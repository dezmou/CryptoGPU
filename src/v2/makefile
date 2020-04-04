
bake: bake.cu broker.cu trade.cu
	nvcc -dc -D BUILD bake.cu broker.cu trade.cu
	nvcc -D BUILD bake.o broker.o trade.o -o bake

play : play.cu broker.cu trade.cu
	nvcc -dc -D BUILD play.cu  broker.cu trade.cu
	nvcc -D BUILD play.o broker.o trade.o -o play
