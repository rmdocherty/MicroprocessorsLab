# -*- coding: utf-8 -*-
"""
Created on Sat Mar 13 17:49:11 2021

@author: Ronan
"""
import serial
import numpy as np
from PIL import Image
import os
import datetime
import uuid

if os.name == 'nt':  #windows label = New Technology
    COM_PORT = 'COM3'
else:  #mac
    COM_PORT = '/dev/tty.usbserial-AG0JH0GF'

#%%

temp_list = []
byte_list = []
image_arr1 = np.zeros((128, 64), dtype=np.uint8)     # First image array - for LHS being correct
image_arr2 = np.zeros((128, 64), dtype=np.uint8)     # Second image array - for RHS being correct
start_flag = False
end_flag = False

# with serial.Serial('COM3', 9600) as ser:  #open COM3 port
with serial.Serial(COM_PORT, 9600) as ser:
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
byte_list_l = byte_list[:len(byte_list)//2]     # Splitting byte_list into two (LHS, RHS)
byte_list_r = byte_list[len(byte_list)//2:]
int_list1 = [int.from_bytes(b, 'big') for b in byte_list_l]  #convert bytes to ints
int_list2 = [int.from_bytes(b, 'big') for b in byte_list_r]  #convert bytes to ints
"""
bogus debug code - to try and figure out bit indices
"""
# for i, val in enumerate(int_list):
#     if val != 0:
#         print(f'Index = {i}, Value pre-binary = {val}')

# bit_list = []
# for i in int_list:
#     if i == 0:
#         split_str = '00000000'
#         ints = [int(d) for d in str(split_str)]
#         # ints = ints[::-1]
#     else:
#         split_str = format(i, '08b')
#         ints = [int(d) for d in str(split_str)]
#         # ints = ints[::-1]
#     # ints = list(map(int, split_str))
#     # print(ints)   
#     for j in ints:
#         bit_list.append(j)

# for j, val in enumerate(bit_list):
#     if val != 0:
#         print(f'Bit index of the 1 = {j}')

def fill_bin(x):  #function to convert int to bit pattern of length 8 (& pad if less)
    bin_out = x
    while len(bin_out) < 8:
        bin_out = "0" + bin_out
    return bin_out

def blockshaped(arr, nrows, ncols): #function to slice 2D arrays
    """
    Return an array of shape (n, nrows, ncols) where
    n * nrows * ncols = arr.size

    If arr is a 2D array, the returned array should look like n subblocks with
    each subblock preserving the "physical" layout of arr.
    """
    h, w = arr.shape
    assert h % nrows == 0, "{} rows is not evenly divisble by {}".format(h, nrows)
    assert w % ncols == 0, "{} cols is not evenly divisble by {}".format(w, ncols)
    return (arr.reshape(h//nrows, nrows, -1, ncols)
               .swapaxes(1,2)
               .reshape(-1, nrows, ncols))
# #%%

for index, b in enumerate(int_list1):
    current_col = index % 128  #current column index
    current_row = index // 128  #current row index
    binary_pattern = format(b, 'b')
    filled_pattern = fill_bin(binary_pattern)
    #reverse bit pattern
    filled_pattern[::-1]
    pattern_list = [int(c) for c in filled_pattern]
    for index, i in enumerate(pattern_list):
        #go downwards with bit pattern rather than up
        image_arr1[current_col, 8 * current_row - index] = i

for index, b in enumerate(int_list2):
    current_col = index % 128  #current column index
    current_row = index // 128  #current row index
    binary_pattern = format(b, 'b')
    filled_pattern = fill_bin(binary_pattern)
    #reverse bit pattern
    filled_pattern[::-1]
    pattern_list = [int(c) for c in filled_pattern]
    for index, i in enumerate(pattern_list):
        #go downwards with bit pattern rather than up
        image_arr2[current_col, 8 * current_row - index] = i

LHS_list = blockshaped(image_arr1, 64, 64)
RHS_list = blockshaped(image_arr2, 64, 64)

image_arr = np.concatenate((LHS_list[0], RHS_list[1]), axis = 0)
image_arr = (np.transpose(image_arr))
image_arr = np.concatenate((image_arr[-8:, 0:127], image_arr[:-8, 0:127]), axis = 0)

scaled = image_arr * 255  #255 = white, 0 = black (not 1/0 as expected)
im = Image.fromarray(scaled, 'L')  #L here means 8 bit black and white
im.show()

"""
Print time and UUID
"""
now = datetime.now()
today = date.today()
current_time = now.strftime("%H:%M:%S")
print(f"Date and Time of Signature: {today}, {current_time}")
print(f"UUID: {str(uuid.uuid4())}")