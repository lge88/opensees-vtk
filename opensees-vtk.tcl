
package require cmdline

set __ele_conn [dict create]
set __ele_vtk_cell [dict create]
set __ele_nn [dict create]
set __ele_type [dict create]

# init element type to number of nodes dictionary
dict set __ele_nn truss 2
dict set __ele_nn elasticBeamColumn 2
dict set __ele_nn quad 4

# init element type to vtk cell type dictionary
dict set __ele_vtk_cell truss 3
dict set __ele_vtk_cell elasticBeamColumn 3
dict set __ele_vtk_cell quad 9

set renamed_model_command "__model__[clock clicks -milliseconds]"
rename model $renamed_model_command

proc model args {
  global __ndm
  global __ndf
  global renamed_model_command
  eval "$renamed_model_command $args"
  set __ndm [eval parse_ndm $args]
  set __ndf [eval parse_ndf $args]
  wrap_element_cmd
}

proc parse_ndm args {
  set len [llength $args]
  for {set i 0} {$i < $len} {incr i} {
    set arg [lindex $args $i]
    if {[string equal $arg "-ndm"] && [expr $i + 1] < $len} {
      return [lindex $args [expr $i + 1]]
    }
  }
  return 2
}

proc parse_ndf {args} {
  set len [llength $args]
  for {set i 0} {$i < $len} {incr i} {
    set arg [lindex $args $i]
    if {[string equal $arg "-ndf"] && [expr $i + 1] < $len} {
      return [lindex $args [expr $i + 1]]
    }
  }
  return 3
}

proc get_ndf {} { global __ndf; return $__ndf; }
proc get_ndm {} { global __ndm; return $__ndm; }

proc wrap_element_cmd {} {
  global element
  global renamed_element_command
  set renamed_element_command "__element__[clock clicks -milliseconds]"
  rename element $renamed_element_command
  proc element args {
    global renamed_element_command
    global __ele_conn
    global __ele_type
    eval "$renamed_element_command $args"
    set etype [lindex $args 0]
    set eid [lindex $args 1]
    set nn [get_ele_nn_by_type $etype]
    set conn [lrange $args 2 [expr 2 + $nn - 1]]
    dict set __ele_conn $eid $conn
    dict set __ele_type $eid $etype
  }
}

proc get_ele_nn eid {
  set etype [get_ele_type $eid]
  return [get_ele_nn_by_type $etype]
}

proc get_ele_nn_by_type etype {
  global __ele_nn
  if {[dict exists $__ele_nn $etype]} {
    return [dict get $__ele_nn $etype]
  } else {
    return []
  }
}

proc get_ele_conn {eid} {
  global __ele_conn
  if {[dict exists $__ele_conn $eid]} {
    return [dict get $__ele_conn $eid]
  } else {
    return []
  }
}

proc get_ele_type eid {
  global __ele_type
  if {[dict exists $__ele_type $eid]} {
    return [dict get $__ele_type $eid]
  } else {
    return ""
  }
}

proc get_ele_vtk_cell eid {
  global __ele_vtk_cell
  set etype [get_ele_type $eid]
  if {[dict exists $__ele_vtk_cell $etype]} {
    return [dict get $__ele_vtk_cell $etype]
  } else {
    return ""
  }
}

proc vtk_output_points {chan} {
  set nids [getNodeTags]
  set num_of_nodes [llength $nids]

  puts $chan "POINTS $num_of_nodes float"

  foreach n $nids {
    set xyz [string trim [nodeCoord $n]]
    set xyz [regexp -inline -all {\S+} $xyz]
    while {[llength $xyz] < 3} { lappend xyz 0.0 }
    puts $chan $xyz
  }
}

proc vtk_count_cell_list_size {eids} {
  set size 0
  foreach eid $eids {
    set nn [get_ele_nn $eid]
    set size [expr $size + $nn + 1]
  }
  return $size
}

proc build_node_indx {nids} {
  set node_indx [dict create]
  set i 0
  foreach n $nids {
    dict set node_indx $n $i
    incr i
  }
  return $node_indx
}

proc map_node_indx {node_indx conn} {
  set res []
  foreach n $conn {
    lappend res [dict get $node_indx $n]
  }
  return $res
}

proc vtk_output_cells {chan} {
  set eids [getEleTags]
  set num_of_eles [llength $eids]
  set cell_list_size [vtk_count_cell_list_size $eids]

  set nids [getNodeTags]
  set node_indx [build_node_indx $nids]

  puts $chan "CELLS $num_of_eles $cell_list_size"
  foreach eid $eids {
    set nn [get_ele_nn $eid]
    set conn [map_node_indx $node_indx [get_ele_conn $eid]]
    puts $chan "$nn $conn"
  }

  puts $chan ""
  puts $chan "CELL_TYPES $num_of_eles"
  foreach eid $eids {
    set cell_type [get_ele_vtk_cell $eid]
    puts $chan $cell_type
  }
}

proc vtk_output_mesh {chan} {
  puts $chan "DATASET UNSTRUCTURED_GRID"
  vtk_output_points $chan
  puts $chan ""
  vtk_output_cells $chan
}

proc vtk_output_meta {chan} {
  puts $chan "# vtk DataFile Version 2.0"
  puts $chan "opensees model"
  puts $chan "ASCII"
}

proc vtk_output_point_data_header {chan} {
  set nids [getNodeTags]
  set num_of_nodes [llength $nids]
  puts $chan ""
  puts $chan "POINT_DATA $num_of_nodes"
}

proc vtk_output_node_disp {chan} {
  set nids [getNodeTags]
  set num_of_nodes [llength $nids]
  set cur_time [getTime]
  set ndf [get_ndf]

  puts $chan "VECTORS node_disp_$cur_time float"
  foreach n $nids {
    set disp [string trim [nodeDisp $n]]
    set disp [regexp -inline -all {\S+} $disp]
    while {[llength $disp] < 3} { lappend disp 0.0 }
    if {$ndf > 3} { set disp [lrange $disp 0 2] }
    puts $chan $disp
  }
  puts $chan ""
}
