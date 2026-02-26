
using namespace System.Linq
using namespace System.Reflection
using namespace System.Reflection.Emit
using namespace System.Linq.Expressions
using namespace System.Runtime.InteropServices

function New-Delegate {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Module,

    [Parameter(Mandatory, Position=1)]
    [ValidateScript({![String]::IsNullOrEmpty($_)})]
    [ScriptBlock]$Signature
  )

  begin {
    if (!($stash = $ExecutionContext.SessionState.PSVariable.Get('PwsHandlesStash'))) {
      $stash = Set-Variable -Name PwsHandlesStash -Value (
        [IntPtr[]]@()
      ) -Visibility Private -Scope Global -PassThru
    }

    if (($mod = $GetModuleHandle.Invoke([buf].Uni($Module))) -eq [IntPtr]::Zero) {
      if (($mod = $LoadLibrary.Invoke([buf].Uni($Module))) -eq [IntPtr]::Zero) {
        throw [DllNotfoundException]::new("Cannot find $Module library.")
      }
      $stash.Value += $mod
    }
  }
  process {}
  end {
    $funcs = @{}
    for ($i, $m, $fn, $p = 0, ([Expression].Assembly.GetType(
        'System.Linq.Expressions.Compiler.DelegateHelpers'
      ).GetMethod('MakeNewCustomDelegate', [BindingFlags]'NonPublic, Static')
      ), [Marshal].GetMethod('GetDelegateForFunctionPointer', ([IntPtr])),
      $Signature.Ast.FindAll({$args[0].CommandElements}, $true).ToArray();
      $i -lt $p.Length; $i++
    ) {
      $fnret, $fname = ($def = $p[$i].CommandElements).Value

      if (($fnsig = $GetProcAddress.Invoke($mod, $fname)) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new("Cannot find $fname signature.")
      }

      $fnargs = $def.Pipeline.Extent.Text
      [Object[]]$fnargs = [String]::IsNullOrEmpty($fnargs) ? $fnret : (
        ($fnargs -replace '\[|\]' -split ',\s+?').ForEach{
          $_.StartsWith('_') ? (Get-Variable $_.Remove(0, 1) -ValueOnly) : $_
        } + $fnret
      )

      $funcs[$fname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $m).Invoke($fnargs)
      ).Invoke([Marshal], $fnsig)
    }

    Add-Member -InputObject $funcs -Name Dispose -MemberType ScriptMethod -Value {
      if (!($stash = $ExecutionContext.SessionState.PSVariable.Get('PwsHandlesStash')).Value) {
        return # nothing to release
      }

      [ParallelEnumerable]::Reverse([ParallelEnumerable]::AsParallel($stash.Value)).ForEach{
        if (!([Boolean]$res = $FreeLibrary.Invoke($_))) { Write-Warning $res }
      }
      $stash.Value = [IntPtr[]]@()
    }

    Set-Variable -Name $Module -Value $funcs -Scope Script -Force
  }
}

Set-Alias -Name coreinfo -Value Get-CpuId
function Get-CpuId {
  [CmdletBinding()]param()

  begin {
    New-Delegate kernelbase {
      ptr VirtualAlloc([ptr, dptr, uint, uint])
      bool VirtualFree([ptr, dptr, uint])
    }

    $bytes = [Byte[]](([IntPtr]::Size -eq 4 ? (
       0x55,                   # push ebp
       0x8B, 0xEC,             # mov ebp, esp
       0x53,                   # push ebx
       0x57,                   # push edi
       0x8B, 0x45, 0x08,       # mov eax, dword ptr[ebp+8]
       0x0F, 0xA2,             # cpuid
       0x8B, 0x7D, 0x0C,       # mov edi, dword ptr[ebp+12]
       0x89, 0x07,             # mov dword ptr[edi+0], eax
       0x89, 0x5F, 0x04,       # mov dword ptr[edi+4], ebx
       0x89, 0x4F, 0x08,       # mov dword ptr[edi+8], ecx
       0x89, 0x57, 0x0C,       # mov dword ptr[edi+12], edx
       0x5F,                   # pop edi
       0x5B,                   # pop ebx
       0x8B, 0xE5,             # mov esp, ebp
       0x5D,                   # pop ebp
       0xC3                    # ret
    ) : (
       0x53,                   # push rbx
       0x49, 0x89, 0xD0,       # mov r8, rdx
       0x89, 0xC8,             # mov eax, ecx
       0x0F, 0xA2,             # cpuid
       0x41, 0x89, 0x40, 0x00, # mov dword ptr[r8+0], eax
       0x41, 0x89, 0x58, 0x04, # mov dword ptr[r8+4], ebx
       0x41, 0x89, 0x48, 0x08, # mov dword ptr[r8+8], ecx
       0x41, 0x89, 0x50, 0x0C, # mov dword ptr[r8+12], edx
       0x5B,                   # pop rbx
       0xC3                    # ret
    )))

    function Get-Blocks {
      param(
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNull()]
        [Byte[]]$Buffer,

        [Parameter()][Switch]$AsInteger,
        [Parameter()][Switch]$AsString
      )

      process {
        $tmp, $reg = @{}, @{
          eax = $Buffer[0..3]
          ebx = $Buffer[4..7]
          ecx = $Buffer[8..11]
          edx = $Buffer[12..15]
        }

        if ($AsInteger) {
          $reg.Keys.ForEach{$tmp.$_ = [BitConverter]::ToInt32($reg.$_, 0)}
        }

        if ($AsString) {
          $reg.Keys.ForEach{$tmp.$_ = -join[Char[]]$reg.$_}
        }

        $tmp
      }
    } # blocks

    function Set-MapFeatures {
      begin {
        function private:New-Hashtable([String[]]$Regs, [Int32[]]$Bits) {
          $out = @{}
          for ($i = 0; $i -lt $Regs.Length; $i++) {
            $out.Add($Regs[$i], $Bits[$i])
          }
          $out
        }

        $chk = for ($i = 0; $i -le 31; $i++) {1 -shl $i}
        # remove candidates
        $edx_low, $ecx_low, $ecx_high = (0x00000400, 0x00100000), 0x00010000, (
          0x00004000, 0x00040000, 0x00100000, 0x02000000, 0x20000000, 0x40000000, 0x80000000
        )
        # fixed
        $edx_high = (
          0x00000800, 0x00080000, 0x00100000, 0x00400000, 0x02000000,
          0x04000000, 0x08000000, 0x20000000, 0x40000000, 0x80000000
        )
        # registers list
        $edx_low_reg = ('fpu;vme;de;pse;tsc;msr;pae;mce;cx8;apic;sep;mtrr;pge;mca;cmov;pat;' +
          'pse36;psn;clfsh;ds;acpi;mmx;fxsr;sse;sse2;ss;htt;tm;ia64;pbe').Split(';')
        $ecx_low_reg = ('sse3;pclmulqdq;dtes64;monitor;ds_cpl;vmx;smx;est;tm2;ssse3;cnxt_id;' +
           'sdbg;fma;cx16;xtpr;pdcm;pcid;dca;sse4_1;sse4_2;x2apic;movbe;popcnt;tsc_deadline;' +
           'aes;xsave;osxsave;avx;f16c;rdrnd;hypervisor').Split(';')
        $edx_high_reg = 'syscall;mp;nx;mmxext;fxsr_opt;pdpe1gb;rdtscp;lm;3dnowext;3dnow'.Split(';')
        $ecx_high_reg = ('lahf_lm;cmp_legacy;svm;extapic;cr8_legacy;abm;sse4a;misalignsse;' +
               '3dnowprefetch;osvw;ibs;xop;skinit;wdt;lwp;fma4;tce;nodeid_msr;tbm;topoext;' +
               'perfctr_core;perfctr_nb;dbx;perftsc;pcx_l2i').Split(';')
        $set = @()
      }
      process {}
      end {
        # construct hashtables
        $edx_low  = $chk.Where{$edx_low  -notcontains $_}
        $ecx_low  = $chk.Where{$ecx_low  -notcontains $_}
        $ecx_high = $chk.Where{$ecx_high -notcontains $_}

        $set += New-Hashtable $edx_low_reg $edx_low
        $set += New-Hashtable $ecx_low_reg $ecx_low
        $set += New-Hashtable $edx_high_reg $edx_high
        $set += New-Hashtable $ecx_high_reg $ecx_high

        $set
      }
    } # features
  }
  process {}
  end {
    try {
      if (($ptr = $kernelbase.VirtualAlloc.Invoke(
        [IntPtr]::Zero, [UIntPtr]::new($bytes.Length), 0x3000, 0x40
      )) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new('Cannot allocate virtual memory block.')
      }

      $cpuid = ConvertFrom-PtrToMethod $ptr ([Action[Int32, [Byte[]]]])
      [Marshal]::Copy($bytes, 0, $ptr, $bytes.Length)

      $buf, $map, $features = [Byte[]]::new(0x10), (Set-MapFeatures), @{}
      $cpuid.Invoke(0, $buf)
      $vendor = "$(($str = Get-Blocks $buf -AsString).ebx)$($str.edx)$($str.ecx)"
      $ll = (Get-Blocks $buf -AsInteger).eax
      for ($i = 0; $i -le $ll; $i++) {
        $cpuid.Invoke($i, $buf)

        if ($i -eq 1) {
          $reg = Get-Blocks $buf -AsInteger

          $map[0].Keys.ForEach{ $features.$_ = $reg.edx -band $map[0].$_ }
          $map[1].Keys.ForEach{ $features.$_ = $reg.ecx -band $map[1].$_ }
        }
      }
      $cpuid.Invoke(0x80000000, $buf)
      $hl = (Get-Blocks $buf -AsInteger).eax
      for ($i = 0x80000000; $i -le $hl; $i++) {
        $cpuid.Invoke($i, $buf)

        if ($i -eq 0x80000001) {
          $reg = Get-Blocks $buf -AsInteger

          $map[2].Keys.ForEach{ $features.$_ = $reg.edx -band $map[2].$_ }
          $map[3].Keys.ForEach{ $features.$_ = $reg.ecx -band $map[3].$_ }
        }

        if ($i -in (0x80000002, 0x80000003, 0x80000004)) {
          $name += "$(($reg = Get-Blocks $buf -AsString).eax)$($reg.ebx)$($reg.ecx)$($reg.edx)"
        }
      }

      [PSCustomObject]@{
        Vendor   = $vendor
        Name     = $name
        Features = $features.Keys.Where{if ($features.$_) { $_ }}
      }
    }
    catch { Write-Verbose $_ }
    finally {
      if ($ptr) {
        if (!$kernelbase.VirtualFree.Invoke($ptr, [UIntPtr]::Zero, 0x8000)) {
          Write-Verbose 'VirtualFree is failed.'
        }
      }
    }
  }
}

Get-CpuId
Start-Sleep 0