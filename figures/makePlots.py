# libraries
import numpy as np
import matplotlib
import matplotlib.pyplot as plt

plt.rcParams["figure.figsize"] = (10,5)

font = {'size'   : 15}

matplotlib.rc('font', **font)

LUT = 0
FF = 1

msp430 = [1840, 692]

dica_16  = [730, 561]
dica_32  = [377, 301]
dica_64  = [193, 170]
dica_128 = [114, 106]
dica_256 = [72, 74]
dica_512 = [49, 58]

lut = [msp430[LUT], dica_16[LUT], dica_32[LUT], dica_64[LUT], dica_128[LUT], dica_256[LUT], dica_512[LUT]]
ff = [msp430[FF], dica_16[FF], dica_32[FF], dica_64[FF], dica_128[FF], dica_256[FF], dica_512[FF]]

bars = ('openMSP430', '16', '32', '64', '128', '256', '512')
x_pos = np.arange(len(bars))
 
# Create bars and choose color https://towardsdatascience.com/how-to-fill-plots-with-patterns-in-matplotlib-58ad41ea8cf8
plt.bar(x_pos - 0.2, lut, 0.4, label="LUT", color='black', edgecolor='black')
plt.bar(x_pos + 0.2, ff, 0.4, label="FF", color='white', edgecolor='black') 

# Show legend
plt.legend()

#Y axis label
plt.ylabel('Total Count')
 
# Create names on the x axis
plt.xticks(x_pos, bars)

# Show graph
# plt.show()

# Save graph
plt.savefig('./dica_hardware.png')


'''
https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf
Basys3 --> Artix 7 part type XC7A35T

https://docs.xilinx.com/v/u/en-US/ds180_7Series_Overview

page 3:
-- XC7A35T has 33,280 logic cells, 5200 CLB slices
-- Each slice contains four LUTs and eight FFs
-- LUTs = 5200*4 = 20,800, FFs = 5200*8 = 41,600

'''