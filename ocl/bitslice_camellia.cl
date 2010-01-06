void F (__private uint *state, int src_idx, int dst_idx);
void FL (__private uint *state);
void InvFL (__private uint *state);

__kernel
void encrypt (__global uint *global_state)
{
	__private uint state[128];
	global_state += get_global_id (0) * 128;

	// copy
	for (int i = 0; i < 128; i ++)
		state[i] = global_state[i];

	for (int j = 0; j < 2; j ++) {
		for (int i = 0; i < 3; i ++) {
			F (state, 0, 64);
			F (state, 64, 0);
		}
		FL (state);
		InvFL (state + 64);
	}
	for (int i = 0; i < 3; i ++) {
		F (state, 0, 64);
		F (state, 64, 0);
	}

	// cross...
	for (int i = 0; i < 64; i ++)
		global_state[i] = state[i + 64];
	for (int i = 0; i < 64; i ++)
		global_state[i + 64] = state[i];
}

__kernel
void bitslice_kernel (__global uint4* state, __local uint4* cache)
{
	const uint4 c1 = (uint4)(1);
	size_t id = get_local_id (0);
	uint4 t = (uint4)(0), cs;
	cache += id & 0xFFFFFFE0;
	state += get_global_id (0) & 0xFFFFFFE0;

	id &= 0x1F;
	cache[id] = state[id];
	barrier (CLK_LOCAL_MEM_FENCE);

	cs = (uint4)(id);
	for (int i = 0; i < 32; i ++)
		t |= ((cache[i] >> cs) & c1) << (uint4)(i);
	state[id] = t;
}

__kernel
void shuffle_state1 (__global uint* state, __local uint* cache)
{
	size_t id = get_local_id (0);
	cache += (id & 0xFFFFFFE0) << 2;
	state += (get_global_id (0) & 0xFFFFFFE0) << 2;

	id &= 0x1F;
	cache[id * 4 + 0] = state[id * 4 + 0];
	cache[id * 4 + 1] = state[id * 4 + 1];
	cache[id * 4 + 2] = state[id * 4 + 2];
	cache[id * 4 + 3] = state[id * 4 + 3];
	barrier (CLK_LOCAL_MEM_FENCE);

	state[id +  0] = cache[id * 4 + 0];
	state[id + 32] = cache[id * 4 + 1];
	state[id + 64] = cache[id * 4 + 2];
	state[id + 96] = cache[id * 4 + 3];
}

__kernel
void shuffle_state2 (__global uint* state, __local uint* cache)
{
	size_t id = get_local_id (0);
	cache += (id & 0xFFFFFFE0) << 2;
	state += (get_global_id (0) & 0xFFFFFFE0) << 2;

	id &= 0x1F;
	cache[id * 4 + 0] = state[id * 4 + 0];
	cache[id * 4 + 1] = state[id * 4 + 1];
	cache[id * 4 + 2] = state[id * 4 + 2];
	cache[id * 4 + 3] = state[id * 4 + 3];
	barrier (CLK_LOCAL_MEM_FENCE);

	state[id * 4 + 0] = cache[id +  0];
	state[id * 4 + 1] = cache[id + 32];
	state[id * 4 + 2] = cache[id + 64];
	state[id * 4 + 3] = cache[id + 96];
}


void S1 (__private uint *input, __private uint *output);
void S2 (__private uint *input, __private uint *output);
void S3 (__private uint *input, __private uint *output);
void S4 (__private uint *input, __private uint *output);
void F (__private uint *state, int src_idx, int dst_idx)
{
#if true
	__private uint t[64];
	S1 (state + src_idx +  0, t +  0);
	S2 (state + src_idx +  8, t +  8);
	S3 (state + src_idx + 16, t + 16);
	S4 (state + src_idx + 24, t + 24);
	S2 (state + src_idx + 32, t + 32);
	S3 (state + src_idx + 40, t + 40);
	S4 (state + src_idx + 48, t + 48);
	S1 (state + src_idx + 56, t + 56);

	for (int i = 0; i < 8; i ++) {
		state[dst_idx + i +  0] ^= t[ 0 + i] ^ t[16 + i] ^ t[24 + i] ^ t[40 + i] ^ t[48 + i] ^ t[56 + i];
		state[dst_idx + i +  8] ^= t[ 0 + i] ^ t[ 8 + i] ^ t[24 + i] ^ t[32 + i] ^ t[48 + i] ^ t[56 + i];
		state[dst_idx + i + 16] ^= t[ 0 + i] ^ t[ 8 + i] ^ t[16 + i] ^ t[32 + i] ^ t[40 + i] ^ t[56 + i];
		state[dst_idx + i + 24] ^= t[ 8 + i] ^ t[16 + i] ^ t[24 + i] ^ t[32 + i] ^ t[40 + i] ^ t[48 + i];
		state[dst_idx + i + 32] ^= t[ 0 + i] ^ t[ 8 + i] ^ t[40 + i] ^ t[48 + i] ^ t[56 + i];
		state[dst_idx + i + 40] ^= t[ 8 + i] ^ t[16 + i] ^ t[32 + i] ^ t[48 + i] ^ t[56 + i];
		state[dst_idx + i + 48] ^= t[16 + i] ^ t[24 + i] ^ t[32 + i] ^ t[40 + i] ^ t[56 + i];
		state[dst_idx + i + 56] ^= t[ 0 + i] ^ t[24 + i] ^ t[32 + i] ^ t[40 + i] ^ t[48 + i];
	}
#else
	__private uint *s = state + src_idx;
	uint8 t;
	uint *p = (uint*)&t;
	uint8 *dv = (uint8*)(state + dst_idx);

	S1 (s + 0, p);
	dv[0] ^= t; dv[1] ^= t; dv[2] ^= t; dv[4] ^= t; dv[7] ^= t; 
	
	S2 (s + 8, p);
	dv[1] ^= t; dv[2] ^= t; dv[3] ^= t; dv[4] ^= t; dv[5] ^= t; 
	
	S3 (s + 16, p);
	dv[0] ^= t; dv[2] ^= t; dv[3] ^= t; dv[5] ^= t; dv[6] ^= t; 
	
	S4 (s + 24, p);
	dv[0] ^= t; dv[1] ^= t; dv[3] ^= t; dv[6] ^= t; dv[7] ^= t; 
	
	S2 (s + 32, p);
	dv[1] ^= t; dv[2] ^= t; dv[3] ^= t; dv[5] ^= t; dv[6] ^= t; dv[7] ^= t; 
	
	S3 (s + 40, p);
	dv[0] ^= t; dv[2] ^= t; dv[3] ^= t; dv[4] ^= t; dv[6] ^= t; dv[7] ^= t; 
	
	S4 (s + 48, p);
	dv[0] ^= t; dv[1] ^= t; dv[3] ^= t; dv[4] ^= t; dv[5] ^= t; dv[7] ^= t; 
	
	S1 (s + 56, p);
	dv[0] ^= t; dv[1] ^= t; dv[2] ^= t; dv[4] ^= t; dv[5] ^= t; dv[6] ^= t; 
#endif
}

void FL (__private uint *state)
{
	for (int i = 0; i < 4; i ++) {
		for (int j = 0; j < 7; j ++)
			state[32 + i * 8 + j + 1] ^= state[i * 8 + j];
	}
	state[32] ^= state[15];
	state[40] ^= state[23];
	state[48] ^= state[31];
	state[56] ^= state[ 7];

	for (int i = 0; i < 32; i ++)
		state[i] ^= state[i + 32];
}

void InvFL (__private uint *state)
{
	for (int i = 0; i < 32; i ++)
		state[i] ^= state[i + 32];

	for (int i = 0; i < 4; i ++) {
		for (int j = 0; j < 7; j ++)
			state[32 + i * 8 + j + 1] ^= state[i * 8 + j];
	}
	state[32] ^= state[15];
	state[40] ^= state[23];
	state[48] ^= state[31];
	state[56] ^= state[ 7];
}

void S1 (__private uint *input, __private uint *output)
{
	uint x0, x1, x2, x3, x4, x5, x6, x7;
	uint a0, a1, a2, a3, b0, b1, b2, b3;
	uint t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14;

	a0 = input[0]; a1 = input[1]; a2 = input[2]; a3 = input[3];
	b0 = input[4]; b1 = input[5]; b2 = input[6]; b3 = input[7];

	/* Isomorphic Mapping */
	t0 = a1 ^ a3 ^ b2 ^ b3;
	a0 ^= t0;
	x0 = a0 ^ a2;
	x1 = a3 ^ b2 ^ 0xFFFFFFFF;
	x2 = a0 ^ b0 ^ 0xFFFFFFFF;
	x3 = a1 ^ b0;
	x4 = a2 ^ t0 ^ 0xFFFFFFFF;
	x5 = a1 ^ b3 ^ 0xFFFFFFFF;
	x6 = a0 ^ a2 ^ b1;
	x7 = a2 ^ b2;

	/* a[0-3] = x[0-3] ^ x[4-7]*/
	a0 = x0 ^ x4; a1 = x1 ^ x5; a2 = x2 ^ x6; a3 = x3 ^ x7;

	/* x[0-3] = a[0-3] * x[0-3] */
	t0 = a3 & x3; t1 = (a2 & x2) ^ t0;
	t2 = t0 ^ (a2 & x3) ^ (a3 & x2);
	t3 = a1 & x1; t4 = (a0 & x0) ^ t3;
	t5 = t3 ^ (a0 & x1) ^ (a1 & x0);
	t0 = a0 ^ a2; t3 = a1 ^ a3;
	x0 ^= x2; x1 ^= x3; t6 = t3 & x1;
	x2 = (t0 & x0) ^ t6 ^ t4;
	x3 = t6 ^ (t0 & x1) ^ (t3 & x0) ^ t5;
	x0 = t2 ^ t4; x1 = t1 ^ t2 ^ t5;

	/* lambda * (a[0-3] * a[0-3]) */
	t0 = x0 ^ x6 ^ x7;
	t1 = x1 ^ x7;
	t2 = x2 ^ x4 ^ x7;
	t3 = x3 ^ x4 ^ x5 ^ x6;

	/* b[0-3] = (x[0-3] * b[0-3])^(-1) in GF(2^4) */
	t4 = t0 & t3; t5 = t1 & t2; t6 = t1 & t3; t7 = t2 & t3;
	t8 = t0 & t5; t9 = t0 & t6; t10 = t0 & t7; t11 = t1 & t7;
	t12 = t1 ^ t2; t13 = t11 ^ t10; t14 = t4 ^ t5;
	b0 = t0 ^ t12 ^ t13 ^ t6 ^ t9 ^ t14 ^ t8;
	b1 = t12 ^ t3 ^ t11 ^ t9 ^ (t0 & t2);
	b2 = t2 ^ t13 ^ t14;
	b3 = t2 ^ t3 ^ t11 ^ t4;

	/* x[0-3] = a[0-3] * b[0-3], x[4-7] = b[0-3] * x[4-7] */
	t0 = b0 ^ b2; 	t1 = b1 ^ b3;
	t2 = b3 & x7; t3 = (b2 & x6) ^ t2;
	t4 = t2 ^ (b2 & x7) ^ (b3 & x6);
	t5 = b1 & x5; t6 = (b0 & x4) ^ t5;
	t7 = t5 ^ (b0 & x5) ^ (b1 & x4);
	t2 = x4 ^ x6; t5 = x5 ^ x7;
	t8 = t1 & t5; x4 = t4 ^ t6;
	x5 = t3 ^ t4 ^ t7;
	x6 = (t0 & t2) ^ t8 ^ t6;
	x7 = t8 ^ (t0 & t5) ^ (t1 & t2) ^ t7;
	t2 = b3 & a3; t3 = (b2 & a2) ^ t2;
	t4 = t2 ^ (b2 & a3) ^ (b3 & a2);
	t5 = b1 & a1; t6 = (b0 & a0) ^ t5;
	t7 = t5 ^ (b0 & a1) ^ (b1 & a0);
	t2 = a0 ^ a2; t5 = a1 ^ a3;
	t8 = t1 & t5; x0 = t4 ^ t6;
	x1 = t3 ^ t4 ^ t7;
	x2 = (t0 & t2) ^ t8 ^ t6;
	x3 = t8 ^ (t0 & t5) ^ (t1 & t2) ^ t7;

	/* Inverse Isomorphic Mapping and S-box */
	t0 = x1 ^ x6;
	t1 = x5 ^ x7;
	output[0] = t1 ^ t0;
	output[1] = x3 ^ x7 ^ 0xFFFFFFFF;
	output[2] = x0 ^ x2 ^ x7 ^ 0xFFFFFFFF;
	t0 ^= x2 ^ x3;
	output[3] = t1 ^ t0 ^ 0xFFFFFFFF;
	output[4] = x0 ^ x2 ^ x5;
	output[5] = x4 ^ t0 ^ 0xFFFFFFFF;
	output[6] = x1 ^ x5 ^ 0xFFFFFFFF;
	output[7] = x1 ^ x3 ^ x5;
}

void S2 (__private uint *input, __private uint *output)
{
	uint t;
	S1 (input, output);
	t = output[7];
	for (int i = 7; i > 0; i --)
		output[i] = output[i - 1];
	output[0] = t;
}

void S3 (__private uint *input, __private uint *output)
{
	uint t;
	S1 (input, output);
	t = output[0];
	for (int i = 0; i < 7; i ++)
		output[i] = output[i + 1];
	output[7] = t;
}

void S4 (__private uint *input, __private uint *output)
{
	uint t;
	t = input[7];
	for (int i = 7; i > 0; i --)
		output[i] = input[i - 1];
	output[0] = t;
	S1 (output, output);
}
