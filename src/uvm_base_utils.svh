// =============================================================================
// File    : uvm_base/src/uvm_base_utils.svh
// Purpose : 通用工具函数（包级函数，所有项目可直接调用）
//           注意：本文件被 include 在 package 内部
// =============================================================================
`ifndef UVM_BASE_UTILS_SVH
`define UVM_BASE_UTILS_SVH

  //----------------------------------------------------------------------------
  // plusarg 读取：失败时返回默认值
  //   例：int n = ub_get_int("NUM_FRAMES", 1);   // +NUM_FRAMES=5
  //----------------------------------------------------------------------------
  function automatic int ub_get_int(string name, int def_val);
    int v;
    if ($value$plusargs({name, "=%d"}, v)) return v;
    return def_val;
  endfunction

  function automatic string ub_get_str(string name, string def_val);
    string v;
    if ($value$plusargs({name, "=%s"}, v)) return v;
    return def_val;
  endfunction

  function automatic bit ub_has_plusarg(string name);
    return ($test$plusargs(name) != 0);
  endfunction

  //----------------------------------------------------------------------------
  // 时间格式化（timescale 无关）
  //----------------------------------------------------------------------------
  function automatic string ub_fmt_ns(time t);
    return $sformatf("%0d ns", t / 1ns);
  endfunction

  function automatic string ub_fmt_us(time t);
    return $sformatf("%0.3f us", (t / 1ns) / 1000.0);
  endfunction

  //----------------------------------------------------------------------------
  // 常用小工具
  //----------------------------------------------------------------------------
  function automatic int ub_max(int a, int b);
    return (a > b) ? a : b;
  endfunction

  function automatic int ub_min(int a, int b);
    return (a < b) ? a : b;
  endfunction

  function automatic int ub_clamp(int v, int lo, int hi);
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
  endfunction

`endif // UVM_BASE_UTILS_SVH
