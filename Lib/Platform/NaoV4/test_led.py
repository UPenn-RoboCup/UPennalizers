import naoqi
from naoqi import ALProxy
dcm = ALProxy("DCM","127.0.0.1",9559)
dcm.createAlias([
"ChestLeds",
[
"ChestBoard/Led/Red/Actuator/Value",
"ChestBoard/Led/Green/Actuator/Value",
"ChestBoard/Led/Blue/Actuator/Value"
]
])

dcm.set([
"ChestLeds",
"ClearAll",
[
[1.0, dcm.getTime(1000)],
[0.0, dcm.getTime(2000)],
[1.0, dcm.getTime(3000)],
[0.0, dcm.getTime(4000)]
]
])

dcm.set([
"ChestBoard/Led/Red/Actuator/Value",
"ClearAll",
[
[1.0, dcm.getTime(1000)],
[0.0, dcm.getTime(2000)],
[1.0, dcm.getTime(3000)],
[0.0, dcm.getTime(4000)]
]
])

dcm.set([
"ChestBoard/Led/Green/Actuator/Value",
"ClearAll",
[
[1.0, dcm.getTime(1000)],
[0.0, dcm.getTime(2000)],
[1.0, dcm.getTime(3000)],
[0.0, dcm.getTime(4000)]
]
])

dcm.set([
"ChestBoard/Led/Blue/Actuator/Value",
"Merge",
[[1.0, dcm.getTime(0)]],
])