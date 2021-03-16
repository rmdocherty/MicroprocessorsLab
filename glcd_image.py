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

with serial.Serial('COM3', 9600) as ser:
    while start_flag is False:
        x = ser.read()
        converted = int.from_bytes(x, "big")
        if x == b's':
            print("Begun recieving from UART!")
            start_flag = True
            byte_list.append(x)
    while end_flag is False:
        x = ser.read()
        byte_list.append(x)
        if x == b'f':
            print("Finished recieving from UART!")
            end_flag = True
    ser.close()

#%%
byte_list = byte_list[1:-1]
int_list = [int.from_bytes(b, 'big') for b in byte_list]


def fill_bin(x):
    bin_out = x
    while len(bin_out) < 8:
        bin_out = "0" + bin_out
    return bin_out


for index, b in enumerate(int_list):
    current_col = index % 128
    current_row = index // 128
    binary_pattern = format(b, 'b')
    filled_pattern = fill_bin(binary_pattern)
    pattern_list = [int(c) for c in filled_pattern]
    for index, i in enumerate(pattern_list):
        image_arr[current_col, 8 * current_row + index] = i


#%%
#converted = np.array(temp_list, dtype=np.uint8)
#reshaped = np.reshape(converted, (8, 1024))
scaled = image_arr * 255
im = Image.fromarray(scaled, 'L')
im.show()
