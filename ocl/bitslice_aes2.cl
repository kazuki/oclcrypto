void subBytes3 (__local uint4 *state)
{
	uint4 x0,x1,x2,x3,x4,x5,x6,x7,t0,t1,t2,t3,t4,t5,t6,m0,m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12;
	for (int i = 0; i < 32; i += 8) {
		x0 = state[i + 0]; x1 = state[i + 1]; x2 = state[i + 2]; x3 = state[i + 3];
		x4 = state[i + 4]; x5 = state[i + 5]; x6 = state[i + 6]; x7 = state[i + 7];
		x5 ^= x0 ^ x6; t0 = x1 ^ x7; x6 ^= x0 ^ x1 ^ x2 ^ x3; x7 ^= x5; x1 ^= x5; x3 ^= x0 ^ x4 ^ t0;
		x4 ^= x5; x2 ^= t0 ^ x5; t1 = x4 ^ x7; t2 = x1 ^ x2; m1 = t1; t5 = x0; m0 = t2; t5 ^= x6; t6 = x3 ^ x5;
		m3 = t5; t4 = t1 ^ t2; t1 &= t5; m2 = t6; t2 &= t6; m4 = t4; t5 ^= t6; t2 ^= t1; t4 &= t5; m5 = t5;
		t6 = x2; t1 ^= t4; t6 &= x3; m6 = t1; t0 = x3; t1 = x2; t0 ^= x0; t1 ^= x4; t5 = x4; m7 = t1; t3 = x7;
		t1 &= t0; t3 &= x6; m8 = t0; t5 &= x0; t6 ^= t1; t5 ^= t1; m11 = x6; t1 = x1; t0 = x5; t1 ^= x7;
		t0 ^= x6; m9 = t1; t5 ^= t2; t4 = x1; m12 = x5; t1 &= t0; t4 &= x5; x6 ^= x7; m10 = t0; t4 ^= t1;
		t3 ^= t1; x5 ^= x1; t1 = m6; t3 ^= t2; t5 ^= x5; t3 ^= x6; t5 ^= x2; t1 ^= x6; t6 ^= x0; t4 ^= t1;
		t6 ^= t1; t4 ^= x5; t6 ^= x4; t2 = t4; t5 ^= x3; t2 ^= t3; x6 = t5; t0 = t5; x6 ^= t6; t0 &= t3;
		x5 = t2; t0 ^= t3; x5 &= x6; t0 ^= t5; x5 ^= t6; t1 = t6; x5 ^= t4; t1 &= t4; t0 ^= x5; t1 ^= x5;
		t6 &= t0; t4 &= t0; x5 = m12; t5 &= t1; t0 ^= t1; t3 &= t1; x6 &= t0; t2 &= t0; t6 ^= x6; t4 ^= t2;
		t5 ^= x6; t3 ^= t2; t1 = t6; x6 = m11; x3 &= t4; t1 ^= t4; t2 = m2; x2 &= t4; m0 &= t1; x5 &= t6;
		t4 ^= t3; x1 &= t6; m7 &= t4; x0 &= t3; t6 ^= t5; t4 &= m8; x4 &= t3; m9 &= t6; x7 &= t5; t3 ^= t5;
		t6 &= m10; x6 &= t5; t2 &= t1; m1 &= t3; x5 ^= t6; t5 = m7; x6 ^= t6; t6 = t1; x3 ^= t4; t1 ^= t3;
		t3 &= m3; x0 ^= t4; x2 ^= t5; m4 &= t1; t2 ^= t3; t1 &= m5; x0 ^= t2; t0 = m0; t1 ^= t3; x4 ^= t5;
		t3 = m9; x6 ^= t2; x3 ^= t1; x5 ^= t1; t6 = x0; t1 = m1; x0 ^= x6; x1 ^= t3; t0 ^= t1; x7 ^= t3;
		t1 ^= m4; x4 ^= t0; x7 ^= t0; x1 ^= t1; x2 ^= t1; t2 = x1; t1 = x4; x1 ^= x6; x4 = x5; x6 = x2;
		x1 ^= x5; x6 ^= x3; t0 = x7; x4 ^= x6; x3 = x0; x7 = x5; x3 ^= x4; x7 ^= x2; x5 = t6; x2 = x7;
		x5 ^= t0; x2 ^= t1; x0 ^= t2; x2 ^= x5;
		state[i + 0] = ~x0; state[i + 1] = ~x1; state[i + 2] = x2; state[i + 3] = x3;
		state[i + 4] = x4; state[i + 5] = ~x5; state[i + 6] = ~x6; state[i + 7] = x7;
	}
}

void subBytes (__local uint4 *state)
{
	uint4 x0, x1, x2, x3, x4, x5, x6, x7;
	uint4 a0, a1, a2, a3, b0, b1, b2, b3;
	uint4 t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14;
	for (int i = 0; i < 32; i += 8) {
		a0 = state[i + 0]; a1 = state[i + 1]; a2 = state[i + 2]; a3 = state[i + 3];
		b0 = state[i + 4]; b1 = state[i + 5]; b2 = state[i + 6]; b3 = state[i + 7];

		/* Isomorphic Mapping */
		x7 = b1 ^ b3; x3 = a1 ^ a2; x6 = x3 ^ a3; x0 = a1 ^ b2;
		x1 = x0 ^ b0; x0 ^= a0;  x2 = x6 ^ b0 ^ b3;
		x3 ^= b2 ^ b3; x4 = x6 ^ x7; x5 = a2 ^ a3 ^ x7; x6 ^= b0 ^ b2 ^ b3;

		/* a[0-3] = x[0-3] ^ x[4-7]*/
		a0 = x0 ^ x4; a1 = x1 ^ x5; a2 = x2 ^ x6; a3 = x3 ^ x7;

		/* lambda * (a[0-3] * a[0-3]) */
		b0 = x4 ^ x5 ^ x7; b1 = x5 ^ x6; b2 = x6 ^ x7;
		b3 = b0 ^ b2; b0 = b2; b2 = b1 ^ x7 ^ b3; b1 = x7;

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

		/* b[0-3] = (x[0-3] * b[0-3])^(-1) in GF(2^4) */
		t0 = b0 ^ x0; t1 = b1 ^ x1; t2 = b2 ^ x2; t3 = b3 ^ x3;
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
		a0 = x0 ^ x1 ^ x2;
		a1 = x6 ^ x7;
		a2 = x0 ^ x7;
		a3 = x2 ^ x7;
		b0 = x4 ^ x5 ^ x6;
		state[i + 0] = ~(a0 ^ a1);
		state[i + 1] = ~a2;
		state[i + 2] = x0 ^ x2 ^ x3 ^ b0;
		state[i + 3] = a0;
		state[i + 4] = a2 ^ x1 ^ x4;
		state[i + 5] = ~a3;
		state[i + 6] = ~(b0 ^ x7);
		state[i + 7] = a3 ^ x3;
	}
}

void shiftRows (__local uint4 *state)
{
	for (int i = 8; i < 16; i ++) state[i] = state[i].s1230;
	for (int i = 16; i < 24; i ++) state[i] = state[i].s2301;
	for (int i = 24; i < 32; i ++) state[i] = state[i].s3012;
	/*
	  state[ 8] = state[ 8].s1230; state[ 9] = state[ 9].s1230;
	  state[10] = state[10].s1230; state[11] = state[11].s1230;
	  state[12] = state[12].s1230; state[13] = state[13].s1230;
	  state[14] = state[14].s1230; state[15] = state[15].s1230;
	  state[16] = state[16].s2301; state[17] = state[17].s2301;
	  state[18] = state[18].s2301; state[19] = state[19].s2301;
	  state[20] = state[20].s2301; state[21] = state[21].s2301;
	  state[22] = state[22].s2301; state[23] = state[23].s2301;
	  state[24] = state[24].s3012; state[25] = state[25].s3012;
	  state[26] = state[26].s3012; state[27] = state[27].s3012;
	  state[28] = state[28].s3012; state[29] = state[29].s3012;
	  state[30] = state[30].s3012; state[31] = state[31].s3012;
	*/
}

void mixColumns (__local uint4 *s)
{
	uint4 t0, t1, t2, t3, t4, t5, t6, t7;
	uint4 q0, q1, q2;
	q0 = s[ 7] ^ s[ 8];
	q1 = s[15] ^ s[16];
	q2 = s[23] ^ s[24];
	t0 = q0 ^ q1 ^ s[24];
	t1 = s[ 0] ^ q1 ^ q2;
	t2 = s[ 0] ^ s[ 8] ^ q2 ^ s[31];
	t3 = s[ 0] ^ q0 ^ s[16] ^ s[31];
	t4 = s[ 0] ^ q0 ^ s[ 9] ^ s[15] ^ s[17] ^ s[25];
	t5 = s[ 1] ^ s[ 8] ^ q1 ^ s[17] ^ s[23] ^ s[25];
	t6 = s[ 1] ^ s[ 9] ^ s[16] ^ q2 ^ s[25] ^ s[31];
	t7 = s[ 0] ^ s[ 1] ^ s[ 7] ^ s[ 9] ^ s[17] ^ s[24] ^ s[31];
	s[0] = t0; s[8] = t1; s[16] = t2; s[24] = t3;
	t0 = s[ 1] ^ s[ 9] ^ s[10] ^ s[18] ^ s[26];
	t1 = s[ 2] ^ s[ 9] ^ s[17] ^ s[18] ^ s[26];
	t2 = s[ 2] ^ s[10] ^ s[17] ^ s[25] ^ s[26];
	t3 = s[ 1] ^ s[ 2] ^ s[10] ^ s[18] ^ s[25];
	s[1] = t4; s[9] = t5; s[17] = t6; s[25] = t7;
	t4 = s[ 2] ^ s[ 7] ^ s[10] ^ s[11] ^ s[15] ^ s[19] ^ s[27];
	t5 = s[ 3] ^ s[10] ^ s[15] ^ s[18] ^ s[19] ^ s[23] ^ s[27];
	t6 = s[ 3] ^ s[11] ^ s[18] ^ s[23] ^ s[26] ^ s[27] ^ s[31];
	t7 = s[ 2] ^ s[ 3] ^ s[ 7] ^ s[11] ^ s[19] ^ s[26] ^ s[31];
	s[2] = t0; s[10] = t1; s[18] = t2; s[26] = t3;
	t0 = s[ 3] ^ s[ 7] ^ s[11] ^ s[12] ^ s[15] ^ s[20] ^ s[28];
	t1 = s[ 4] ^ s[11] ^ s[15] ^ s[19] ^ s[20] ^ s[23] ^ s[28];
	t2 = s[ 4] ^ s[12] ^ s[19] ^ s[23] ^ s[27] ^ s[28] ^ s[31];
	t3 = s[ 3] ^ s[ 4] ^ s[ 7] ^ s[12] ^ s[20] ^ s[27] ^ s[31];
	s[3] = t4; s[11] = t5; s[19] = t6; s[27] = t7;
	t4 = s[ 4] ^ s[12] ^ s[13] ^ s[21] ^ s[29];
	t5 = s[ 5] ^ s[12] ^ s[20] ^ s[21] ^ s[29];
	t6 = s[ 5] ^ s[13] ^ s[20] ^ s[28] ^ s[29];
	t7 = s[ 4] ^ s[ 5] ^ s[13] ^ s[21] ^ s[28];
	s[4] = t0; s[12] = t1; s[20] = t2; s[28] = t3;
	t0 = s[ 5] ^ s[13] ^ s[14] ^ s[22] ^ s[30];
	t1 = s[ 6] ^ s[13] ^ s[21] ^ s[22] ^ s[30];
	t2 = s[ 6] ^ s[14] ^ s[21] ^ s[29] ^ s[30];
	t3 = s[ 5] ^ s[ 6] ^ s[14] ^ s[22] ^ s[29];
	s[5] = t4; s[13] = t5; s[21] = t6; s[29] = t7;
	t4 = s[ 6] ^ s[14] ^ s[15] ^ s[23] ^ s[31];
	t5 = s[ 7] ^ s[14] ^ s[22] ^ s[23] ^ s[31];
	t6 = s[ 7] ^ s[15] ^ s[22] ^ s[30] ^ s[31];
	t7 = s[ 6] ^ s[ 7] ^ s[15] ^ s[23] ^ s[30];
	s[6] = t0; s[7] = t4; s[14] = t1; s[15] = t5;
	s[22] = t2; s[23] = t6; s[30] = t3; s[31] = t7;
}

void bitslice (const __global uint4* input,
               __local uint4 *state)
{
	const uint4 c1 = (uint4)(1);
	for (int i = 0; i < 32; i ++) state[i] = (uint4)(0);
	for (int i = 0; i < 32; i += 8) {
		uint4 t0 = input[i + 0], t1 = input[i + 1];
		uint4 t2 = input[i + 2], t3 = input[i + 3];
		uint4 t4 = input[i + 4], t5 = input[i + 5];
		uint4 t6 = input[i + 6], t7 = input[i + 7];
		for (int j = 0; j < 32; j ++) {
			state[j] |=
				(((t0 >> (uint4)(j)) & c1) << (uint4)(i + 0)) |
				(((t1 >> (uint4)(j)) & c1) << (uint4)(i + 1)) |
				(((t2 >> (uint4)(j)) & c1) << (uint4)(i + 2)) |
				(((t3 >> (uint4)(j)) & c1) << (uint4)(i + 3)) |
				(((t4 >> (uint4)(j)) & c1) << (uint4)(i + 4)) |
				(((t5 >> (uint4)(j)) & c1) << (uint4)(i + 5)) |
				(((t6 >> (uint4)(j)) & c1) << (uint4)(i + 6)) |
				(((t7 >> (uint4)(j)) & c1) << (uint4)(i + 7));
		}
	}
}

void unbitslice (__local uint4 *state,
                 __global uint4* output)
{
	const uint4 c1 = (uint4)(1);
	for (int i = 0; i < 32; i += 2) {
		uint4 t0 = (uint4)(0);
		uint4 t1 = (uint4)(0);
		for (int j = 0; j < 32; j ++) {
			t0 |= ((state[j] >> (uint4)(i + 0)) & c1) << (uint4)(j);
			t1 |= ((state[j] >> (uint4)(i + 1)) & c1) << (uint4)(j);
		}
		output[i] = t0;
		output[i + 1] = t1;
	}
}

__kernel
void encrypt1 (__global uint4* global_mem,
              const __global uint4* key,
              __local uint4* state
)
{
	const int rounds = 10;
	global_mem += get_global_id (0) * 32;
	state += get_local_id (0) * 32;
	bitslice (global_mem, state);
	for (int i = 0; i < 32; i ++)
		state[i] ^= key[i];
	for (uint i = 1; i < rounds; i ++) {
		subBytes (state);
		shiftRows (state);
		mixColumns (state);
		for (int j = 0; j < 32; j ++)
			state[j] = state[j] ^ key[i * 32 + j];
	}
	subBytes (state);
	shiftRows (state);
	for (int i = 0; i < 32; i ++)
		state[i] ^= key[10 * 32 + i];
	unbitslice (state, global_mem);
}

__kernel
void encrypt2 (__global uint4* global_state,
               const __global uint4* key,
               __local uint4* state
)
{
	const int rounds = 10;
	global_state += get_global_id (0) * 32;
	state += get_local_id (0) * 32;

	for (int i = 0; i < 32; i ++)
		state[i] = global_state[i] ^ key[i];
	key += 32;
	for (uint i = 1; i < rounds; i ++, key += 32) {
		subBytes (state);
		shiftRows (state);
		mixColumns (state);
		for (int j = 0; j < 32; j += 8) {
			state[j    ] ^= key[j    ]; state[j + 1] ^= key[j + 1];
			state[j + 2] ^= key[j + 2]; state[j + 3] ^= key[j + 3];
			state[j + 4] ^= key[j + 4]; state[j + 5] ^= key[j + 5];
			state[j + 6] ^= key[j + 6]; state[j + 7] ^= key[j + 7];
		}
	}
	subBytes (state);
	shiftRows (state);

	for (int i = 0; i < 32; i ++)
		global_state[i] = state[i] ^ key[i];
}

__kernel
void bitslice_kernel (__global uint4* state)
{
	const uint4 c1 = (uint4)(1);
	state += get_global_id (0) * 32;

	uint4 t0 = state[0], t1 = state[1];
	uint4 t2 = state[2], t3 = state[3];
	uint4 t4 = state[4], t5 = state[5];
	uint4 t6 = state[6], t7 = state[7];
	uint4 t8 = state[8], t9 = state[9];
	uint4 t10 = state[10], t11 = state[11];
	uint4 t12 = state[12], t13 = state[13];
	uint4 t14 = state[14], t15 = state[15];
	uint4 t16 = state[16], t17 = state[17];
	uint4 t18 = state[18], t19 = state[19];
	uint4 t20 = state[20], t21 = state[21];
	uint4 t22 = state[22], t23 = state[23];
	uint4 t24 = state[24], t25 = state[25];
	uint4 t26 = state[26], t27 = state[27];
	uint4 t28 = state[28], t29 = state[29];
	uint4 t30 = state[30], t31 = state[31];
	for (int j = 0; j < 32; j ++) {
		const uint4 cj = (uint4)(j);
		state[j] =
			(((t0 >> cj) & c1) << (uint4)(0)) |
			(((t1 >> cj) & c1) << (uint4)(1)) |
			(((t2 >> cj) & c1) << (uint4)(2)) |
			(((t3 >> cj) & c1) << (uint4)(3)) |
			(((t4 >> cj) & c1) << (uint4)(4)) |
			(((t5 >> cj) & c1) << (uint4)(5)) |
			(((t6 >> cj) & c1) << (uint4)(6)) |
			(((t7 >> cj) & c1) << (uint4)(7)) |
			(((t8 >> cj) & c1) << (uint4)(8)) |
			(((t9 >> cj) & c1) << (uint4)(9)) |
			(((t10 >> cj) & c1) << (uint4)(10)) |
			(((t11 >> cj) & c1) << (uint4)(11)) |
			(((t12 >> cj) & c1) << (uint4)(12)) |
			(((t13 >> cj) & c1) << (uint4)(13)) |
			(((t14 >> cj) & c1) << (uint4)(14)) |
			(((t15 >> cj) & c1) << (uint4)(15)) |
			(((t16 >> cj) & c1) << (uint4)(16)) |
			(((t17 >> cj) & c1) << (uint4)(17)) |
			(((t18 >> cj) & c1) << (uint4)(18)) |
			(((t19 >> cj) & c1) << (uint4)(19)) |
			(((t20 >> cj) & c1) << (uint4)(20)) |
			(((t21 >> cj) & c1) << (uint4)(21)) |
			(((t22 >> cj) & c1) << (uint4)(22)) |
			(((t23 >> cj) & c1) << (uint4)(23)) |
			(((t24 >> cj) & c1) << (uint4)(24)) |
			(((t25 >> cj) & c1) << (uint4)(25)) |
			(((t26 >> cj) & c1) << (uint4)(26)) |
			(((t27 >> cj) & c1) << (uint4)(27)) |
			(((t28 >> cj) & c1) << (uint4)(28)) |
			(((t29 >> cj) & c1) << (uint4)(29)) |
			(((t30 >> cj) & c1) << (uint4)(30)) |
			(((t31 >> cj) & c1) << (uint4)(31));
	}
}

__kernel 
void bitslice_key (__constant uchar* expandedKey,
                   __global   uint4*  bitsliceKey)
{
	size_t gid = get_global_id (0);
	int q = gid >> 5;
	int g = (q << 7) + (gid & 0x1F);
	int k = g >> 3;
	int j = g & 7;

	bitsliceKey[gid] =
		(uint4)(((expandedKey[k +  0] >> j) & 1) == 0 ? 0 : 0xffffffff,
				  ((expandedKey[k +  4] >> j) & 1) == 0 ? 0 : 0xffffffff,
				  ((expandedKey[k +  8] >> j) & 1) == 0 ? 0 : 0xffffffff,
				  ((expandedKey[k + 12] >> j) & 1) == 0 ? 0 : 0xffffffff);
}
