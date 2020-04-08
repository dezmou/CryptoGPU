bake: bake.cu broker.cu trade.cu analyse.cu trade.h
	nvcc -dc -D BUILD bake.cu broker.cu trade.cu analyse.cu
	nvcc bake.o broker.o trade.o analyse.o -o bake

play : play.cu broker.cu trade.cu analyse.cu trade.h
	nvcc -dc -D BUILD -D PLAY play.cu  broker.cu trade.cu analyse.cu
	nvcc play.o broker.o trade.o analyse.o -o play

replay : play.cu broker.cu trade.cu analyse.cu trade.h
	nvcc -dc -D BUILD -D PLAY -D REPLAY play.cu  broker.cu trade.cu analyse.cu
	nvcc play.o broker.o trade.o analyse.o -o play

