# -*- coding: utf-8 -*-
"""
Created on Sat Mar 13 17:49:11 2021

@author: Ronan
"""
import serial
import numpy as np
from PIL import Image

#%%

temp_list = []
byte_list = []
image_arr = np.zeros((128, 64), dtype=np.uint8)
start_flag = False
end_flag = False

with serial.Serial('COM3', 9600) as ser:  #open COM3 port
    while start_flag is False:  #transmission hasn't started yet
        x = ser.read()  #keep reading
        converted = int.from_bytes(x, "big")  #big endian
        if x == b's':  #start flag
            print("Begun recieving from UART!")
            start_flag = True
            byte_list.append(x)
    while end_flag is False:  #loop until we recieve the end byte, 'f'
        x = ser.read()
        byte_list.append(x)
        if x == b'f':
            print("Finished recieving from UART!")
            end_flag = True
    ser.close()  #close port

#%%
byte_list = byte_list[1:-1]  #strip start and end flags
int_list = [int.from_bytes(b, 'big') for b in byte_list]  #convert bytes to ints


def fill_bin(x):  #function to convert int to bit pattern of length 8 (& pad if less)
    bin_out = x
    while len(bin_out) < 8:
        bin_out = "0" + bin_out
    return bin_out
#%%

for index, b in enumerate(int_list):
    current_col = index % 128  #current column index
    current_row = index // 128  #current row index
    binary_pattern = format(b, 'b')
    filled_pattern = fill_bin(binary_pattern)
    #reverse bit pattern
    filled_pattern[::-1]
    pattern_list = [int(c) for c in filled_pattern]
    for index, i in enumerate(pattern_list):
        #go downwards with bit pattern rather than up
        image_arr[current_col, 8 * current_row - index] = i


scaled = image_arr * 255  #255 = white, 0 = black (not 1/0 as expected)
im = Image.fromarray(scaled, 'L')  #L here means 8 bit black and white
im.show()
