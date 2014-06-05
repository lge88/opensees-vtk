
source ../opensees-vtk.tcl

source quad.tcl
set fd [open "./quad.out.vtk" "w"]
vtk_output_meta $fd
vtk_output_mesh $fd
vtk_output_point_data_header $fd

analyze 1
vtk_output_node_disp $fd

analyze 1
vtk_output_node_disp $fd

analyze 1
vtk_output_node_disp $fd

analyze 1
vtk_output_node_disp $fd

analyze 1
vtk_output_node_disp $fd

close $fd
