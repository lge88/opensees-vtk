
wipe;
model basic -ndm 2 -ndf 2

set A 1
set B 2
set C 3
set D 4
set E 5

node $A 0.0 0.0
node $B 2.0 0.0
node $C 4.0 0.0
node $D 2.0 -1.5
node $E 4.0 -3.0

uniaxialMaterial Elastic 1 1

element truss 1 $A $B 1.0 1
element truss 2 $A $D 1.0 1
element truss 3 $B $C 1.0 1
element truss 4 $D $C 1.0 1
element truss 5 $D $E 1.0 1
element truss 6 $D $B 1.0 1

fix $C 1 1
fix $E 1 1

timeSeries Constant 1
pattern Plain 1 1 {
  load $A 0.0 -2.0
  load $B 0.0 -3.0
}

constraints Plain
integrator LoadControl 1
test NormUnbalance 1.0e-6 30
algorithm Linear
numberer Plain
system BandGeneral
analysis Static

# analyze 1

# set T1 [eleResponse 1 axialForce]
# set T2 [eleResponse 2 axialForce]
# set T3 [eleResponse 3 axialForce]
# set T4 [eleResponse 4 axialForce]
# set T5 [eleResponse 5 axialForce]
# set T6 [eleResponse 6 axialForce]

# # format to float:
# set T1 [expr $T1]
# set T2 [expr $T2]
# set T3 [expr $T3]
# set T4 [expr $T4]
# set T5 [expr $T5]
# set T6 [expr $T6]

# set res [list $T1 $T2 $T3 $T4 $T5 $T6]


# foreach name {T1 T2 T3 T4 T5 T6}\
#     unit {kN kN kN kN kN kN} val $res {
#       set val [format "%.6f" $val]
#       puts "${name} ($unit) = $val"
#     }

# puts [getNodeTags]
