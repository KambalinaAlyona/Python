# Программа для создания одноканального изображения и масштабирования
# в 2 раза с помощью библиотеки OpenCL

import numpy as np
from PIL import Image
import pyopencl as ocl
import timeit

f = open("lab.cl", "r", encoding = "utf-8")
kernels = ''.join(f.readlines())
f.close()

def opencl_quantize():
	ctx = cl.Contect(devices=[device], dev_type = None)
    queue = cl.CommandQueue(ctx)
	mf = cl.mem_flags
	
	quantize = cl.Program(ctx, kernels).build().quantize
	
	red = np.array(channels[0]).astype(np.uint8)
	green = np.array(channels[1]).astype(np.uint8)
	blue = np.array(channels[2]).astype(np.uint8)
	
	red_g = cl.Buffer(ctx, mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = red)
	green_g = cl.Buffer(ctx, mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = green)
	blue_g = cl.Buffer(ctx, mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = blue)
	
	quantize(queue, red.shape, (8, 16), red_g, green_g, blue_g)
	
	cl.enqueue_copy(queue, red, red_g)
	cl.enqueue_copy(queue, green, green_g)
	cl.enqueue_copy(queue, blue, blue_g)
	
	return red, green, blue
	
source_dir = './Source_Files/'
result_dir = './Result_Files/'
	
img = '1024.jpg'

image = Image.open(source_dir + image)
channels = image.split()

red = np.array(channels[0]).astype(np.uint8)
green = np.array(channels[1]).astype(np.uint8)
blue = np.array(channels[2]).astype(np.uint8)

device = cl.get_platforms()[2].get_devices()[0]
t = timeit.Timer(lambda: opencl_quantize(red, green, blue))
print('CPU time', t.timeit(number = 10))

device = cl.get_platforms()[0].get_devices()[0]
t = timeit.Timer(lambda: opencl_quantize(red, green, blue))
print('GPU time', t.timeit(number = 10))

red, green, blue = opencl_quantize(red, green, blue)

new_channels = np.array([red, green, blue])
new_channels = np.moveaxis(new_channels, 0, -1)
new_channels.shape

image_quantize = Image.fromarray(new_channels)
image_quantize.save(result_dir + quantize)
