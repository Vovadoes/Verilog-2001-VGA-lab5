import os.path
from pprint import pprint

from setting import *

with open(os.path.join(VIVADO_PROJECT,
                       os.path.join("Lab5v1.sim", "sim_1", "behav", "xsim",
                                    "images", "vgaRGB.txt")), "br") as f:
    fileRGB = f.read()

with open(os.path.join(VIVADO_PROJECT,
                       os.path.join("Lab5v1.sim", "sim_1", "behav", "xsim",
                                    "images", "fileHsync.txt")), "br") as f:
    fileHsync = f.read()

with open(os.path.join(VIVADO_PROJECT,
                       os.path.join("Lab5v1.sim", "sim_1", "behav", "xsim",
                                    "images", "fileVsync.txt")), "br") as f:
    fileVsync = f.read()

# print(fileRGB)
print(len(fileRGB))

# print(fileHsync)
print(len(fileHsync))

# print(fileVsync)
# print(len(fileVsync))
#
# fileRGB = fileRGB + b'0'
print(len(fileRGB))
lstRGB = []

for i in range(0, len(fileRGB), 12):
    if i + 12 <= len(fileRGB):
        # lstRGB.append(fileRGB[i:i+12])
        lstRGB.append((int(fileRGB[i:i + 4], 2), int(fileRGB[i + 4:i + 8], 2), int(fileRGB[i + 8:i + 12], 2)))
    else:
        print("кадр не целый")

# pprint(lstRGB)
print(len(fileRGB) / 12)

lstHsync = []

print(len(fileHsync[0: SIZE_H]), SIZE_H)
print(fileHsync[0: SIZE_H])
print(fileHsync[SIZE_H: SIZE_H * 2])
print(fileHsync[SIZE_H * 2: SIZE_H * 3])


for i in range(0, len(fileHsync), SIZE_H):
    if i + SIZE_H <= len(fileRGB):
        lstHsync.append(fileHsync[i:i + SIZE_H])
    else:
        print("кадр не целый")
pprint(len(lstHsync))

with open("fileHsync.txt", "w") as f:
    for i in lstHsync:
        f.write(i.decode("utf-8"))
        f.write("\n")



generHsync = b"1" * (ACTIVE_VIDEO_H + FRONT_PORCH_H) + b"0" * SYNC_PULSE_H + b'1' * BACK_PORCH_H
generVsync = b"1" * (ACTIVE_VIDEO_V + FRONT_PORCH_V) + b"0" * SYNC_PULSE_V + b'1' * BACK_PORCH_V

print(generHsync)
print(generVsync)

x = 0
y = 0

lstRGB_normal = []

for y in range(SIZE_V):
    for x in range(SIZE_H):
        if generHsync[x] != fileHsync[x]:
            pass
    if lstHsync[y] != generHsync:
        print(lstHsync[y])
        print(generHsync)
        print(x, y)
        # print("{0:b}".format(generHsync[y]))
        print("Error")
        break
