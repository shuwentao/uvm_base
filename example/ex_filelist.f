// =============================================================================
// uvm_base 示例工程文件列表（验证 uvm_base 与具体协议无关）
//   路径相对 uvm_base 根目录（VCS 以当前工作目录解析 -f 中的相对路径）
//   cd uvm_base && vcs -f ./example/ex_filelist.f -top ex_top
// =============================================================================
+incdir+./src
+incdir+./example

./src/uvm_base_pkg.sv
./example/ex_if.sv
./example/ex_dut.sv
./example/ex_pkg.sv
./example/ex_top.sv
