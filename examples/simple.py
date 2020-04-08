from __future__ import print_function

# show mono16 format logic
import numpy
import motmot.imops.imops as imops

h = 2
w = 3
fin = numpy.zeros((h, w), dtype=numpy.uint16)
fin[0, 0] = 255
fin[0, 1] = 255 << 4

fin2 = numpy.frombuffer(fin.tobytes(), dtype=numpy.uint8)
fin2.shape = fin.shape[0], fin.shape[1] * 2
fout = imops.mono16_to_mono8_middle8bits(fin2)
print("fin[0,0], fout[0,0]", fin[0, 0], fout[0, 0])
print("fin[0,1], fout[0,1]", fin[0, 1], fout[0, 1])
print("fin[0,2], fout[0,2]", fin[0, 2], fout[0, 2])


h = 2
w = 3
fin3 = numpy.zeros((h, w), dtype=numpy.uint8)
fin3[0, 0] = 255
fin3[0, 1] = 10

print("fin3", fin3)

fout3 = imops.mono8_to_rgb8(fin3)
print("fout3 R\n", fout3[:, :, 0])
print("fout3 G\n", fout3[:, :, 1])
print("fout3 B\n", fout3[:, :, 2])
