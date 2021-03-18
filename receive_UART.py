import serial
import numpy as np
from PIL import Image

byte_list = []
image_arr = np.zeros((64, 128), dtype=np.uint8)     # Gives 128 columns, 64 rows as intended (row, column)
start_flag = False
end_flag = False

# with serial.Serial('COM3', 9600) as ser:
with serial.Serial('/dev/tty.usbserial-AG0JH0GF', 9600) as ser:
    while start_flag is False:
        x = ser.read()
        converted = int.from_bytes(x, "big")
        if x == b's':
            print("Begun receiving from UART!")
            start_flag = True
            byte_list.append(x)
    while end_flag is False:
        x = ser.read()
        byte_list.append(x)
        if x == b'f':
            print("Finished receiving from UART!")
            end_flag = True
    ser.close()

#%%
byte_list = byte_list[1:-1] # First byte is 's' --> sending flag
int_list = [int.from_bytes(b, 'big') for b in byte_list]        # 1024 bytes represented by integers.
"""
First 512 bytes: left half of screen. Second 512 bytes: right half of screen
0   1   2       8 bits that form each byte go downwards
0   1   2   
0   1   2
0   1   2
0   1   2
0   1   2
0   1   2
0   1   2

64  65  66  ...

Convert int_list to bit list --> first 8 bits are (row, column) --> (0,0), (1,0), (2,0) etc.
2 counters: 0 --> 7, after 7th bit is appended, reset and move to next column, 0 --> 63, after 63rd bit is appended, move to next set of 8 rows
"""

def fill_bin(x):
    bin_out = x
    while len(bin_out) < 8:
        bin_out = "0" + bin_out
    return bin_out

bit_list = []
# Splitting binary to string then back to individual ints
for i in int_list:
    if i == 0:
        split_str = '00000000'
        ints = [int(d) for d in str(split_str)]
    else:
        split_str = format(i, '08b')
        ints = [int(d) for d in str(split_str)]
    # ints = list(map(int, split_str))
    # print(ints)   
    for j in ints:
        bit_list.append(j)

# Saving to txt just to test
bit_array = np.asarray(bit_list, dtype = np.uint8)
reshaped_array = bit_array.reshape(64, 128)
np.savetxt('test1024.txt', reshaped_array, fmt = '%i', delimiter = ' ')
print(reshaped_array)

bit_count = 0   #0-7
col_count = 0   #0-63
page_count = 0  #0-7
# side_count = 0  #0-1
# LHS of screen - should be first half of 8192 bits
for ind, pixel in enumerate(bit_list[0:4095]):
    bit_count = ind % 8

    # if ind <= 4095:
    #     side_count = 0
    # else:
    #     side_count = 1
    page_count = int(ind / 512) # each page = 512 bits
    col_index = int(ind / 8) - (page_count * 64)
    # if side_count == 0:
    #     page_count = int(ind / 512)
    # else:
    #     page_count = int(ind / 512) - 8
    row_index = (8 * page_count) + bit_count
    if pixel == 1:
        print(bit_count, col_index, page_count)
    image_arr[row_index, col_index] = pixel

# RHS of screen - should be second half of 8192 bits
for ind, pixel in enumerate(bit_list[4096:]):
    bit_count = ind % 8
    page_count = int(ind / 512)
    col_index = (int(ind / 8) - (page_count * 64)) + 64 # column index is 64 + (0 to 64) for second half
    row_index = (8 * page_count) + bit_count
    if pixel == 1:
        print(bit_count, col_index, page_count)
    image_arr[row_index, col_index] = pixel

scaled = image_arr * 255
im = Image.fromarray(scaled, 'L')
im.show()