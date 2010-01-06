#define BLOCK_BITS   128
#define BLOCK_BYTES  16
#define VECTOR_BITS  128
#define VECTOR_BYTES 16

void shiftRows (__local uint4* src, __local uint4* dst, uint localId)
{
	uint new_adrs = ((((localId >> 5) - (localId >> 3)) & 3) << 5) | (localId & 31);
	dst[new_adrs] = src[localId];
}

uint shiftRows1 (uint localId)
{
	return ((((localId >> 5) - (localId >> 3)) & 3) << 5) | (localId & 31);
}

uint shiftRows2 (uint localId)
{
	return ((((localId >> 5) + ((localId >> 3) & 3)) & 3) << 5) | (localId & 31);
}

uint4 mixColumns (__local uint4* src, uint localId)
{
	uint b = localId & 0x1F;
	uint offset = localId & 0xE0;
	uint4 x = src[shiftRows2 (offset + ((b + 7) & 0x1F))] ^ src[shiftRows2 (offset + ((b + 8) & 0x1F))]
		^ src[shiftRows2 (offset + ((b + 16) & 0x1F))] ^ src[shiftRows2 (offset + ((b + 24) & 0x1F))]
		^ src[shiftRows2 (offset + ((b + 31) & 0x1F))];
	switch (b & 7) {
	case 0:
		x ^= src[shiftRows2 (offset + ((b + 15) & 0x1F))] ^ src[shiftRows2 (offset + ((b + 31) & 0x1F))];
		break;
	case 1:
		x ^= src[shiftRows2 (offset + ((b + 6) & 0x1F))] ^ src[shiftRows2 (offset + ((b + 14) & 0x1F))];
		break;
	case 3:
		x ^= src[shiftRows2 (offset + ((b + 4) & 0x1F))] ^ src[shiftRows2 (offset + ((b + 12) & 0x1F))];
		break;
	case 4:
		x ^= src[shiftRows2 (offset + ((b + 3) & 0x1F))] ^ src[shiftRows2 (offset + ((b + 11) & 0x1F))];
		break;
	}
	return x;
}

void subBytes (__local uint4* src, __local uint4* dst, uint localId)
{
	uint bitpos = localId & 7;
	uint baseId = localId & (~7);
	if (bitpos != 0)
		return;

	/* Inverse in GF(2^8) */

	/* Isomorphic Mapping */
	uint4 x0, x1, x2, x3, x4, x5, x6, x7;
	x0 = src[baseId + 0] ^ src[baseId + 1] ^ src[baseId + 6];
	x1 = src[baseId + 1] ^ src[baseId + 4] ^ src[baseId + 6];
	x2 = src[baseId + 1] ^ src[baseId + 2] ^ src[baseId + 3] ^ src[baseId + 4] ^ src[baseId + 7];
	x3 = src[baseId + 1] ^ src[baseId + 2] ^ src[baseId + 6] ^ src[baseId + 7];
	x4 = src[baseId + 1] ^ src[baseId + 2] ^ src[baseId + 3] ^ src[baseId + 5] ^ src[baseId + 7];
	x5 = src[baseId + 2] ^ src[baseId + 3] ^ src[baseId + 5] ^ src[baseId + 7];
	x6 = src[baseId + 1] ^ src[baseId + 2] ^ src[baseId + 3] ^ src[baseId + 4] ^ src[baseId + 6] ^ src[baseId + 7];
	x7 = src[baseId + 5] ^ src[baseId + 7];

	/* a[0-3] = x[0-3] ^ x[4-7]*/
	uint4 a0 = x0 ^ x4;
	uint4 a1 = x1 ^ x5;
	uint4 a2 = x2 ^ x6;
	uint4 a3 = x3 ^ x7;

	/* lambda * (a[0-3] * a[0-3]) */
	uint4 b0, b1, b2, b3;
	b0 = x4 ^ x5 ^ x7;
	b1 = x5 ^ x6;
	b2 = x6 ^ x7;
	b3 = b0 ^ b2;
	b0 = b2;
	b2 = b1 ^ x7 ^ b3;
	b1 = x7;

	/* x[0-3] = a[0-3] * x[0-3] */
	{
		uint4 ht = a3 & x3;
		uint4 h0 = (a2 & x2) ^ ht;
		uint4 h1 = ht ^ (a2 & x3) ^ (a3 & x2);
		uint4 lt = a1 & x1;
		uint4 l0 = (a0 & x0) ^ lt;
		uint4 l1 = lt ^ (a0 & x1) ^ (a1 & x0);
		uint4 z0 = a0 ^ a2;
		uint4 z1 = a1 ^ a3;
		uint4 y0 = x0 ^ x2;
		uint4 y1 = x1 ^ x3;
		uint4 mt = z1 & y1;
		x2 = (z0 & y0) ^ mt ^ l0;
		x3 = mt ^ (z0 & y1) ^ (z1 & y0) ^ l1;
		x0 = h1 ^ l0;
		x1 = h0 ^ h1 ^ l1;
	}

	/* b[0-3] = (x[0-3] * b[0-3])^(-1) in GF(2^4) */
	{
		uint4 t0 = b0 ^ x0;
		uint4 t1 = b1 ^ x1;
		uint4 t2 = b2 ^ x2;
		uint4 t3 = b3 ^ x3;
		uint4 and03 = t0 & t3;
		uint4 and12 = t1 & t2;
		uint4 and13 = t1 & t3;
		uint4 and23 = t2 & t3;
		uint4 and012 = t0 & and12;
		uint4 and013 = t0 & and13;
		uint4 and023 = t0 & and23;
		uint4 and123 = t1 & and23;
		uint4 xor12 = t1 ^ t2;
		uint4 xor_and123_and023 = and123 ^ and023;
		uint4 xor_and03_and12 = and03 ^ and12;
		b0 = t0 ^ xor12 ^ xor_and123_and023 ^ and13 ^ and013 ^ xor_and03_and12 ^ and012;
		b1 = xor12 ^ t3 ^ and123 ^ and013 ^ (t0 & t2);
		b2 = t2 ^ xor_and123_and023 ^ xor_and03_and12;
		b3 = t2 ^ t3 ^ and123 ^ and03;
	}

	/* x[0-3] = a[0-3] * b[0-3], x[4-7] = b[0-3] * x[4-7] */
	{
		uint4 z0 = b0 ^ b2;
		uint4 z1 = b1 ^ b3;
		{
			uint4 ht = b3 & x7;
			uint4 h0 = (b2 & x6) ^ ht;
			uint4 h1 = ht ^ (b2 & x7) ^ (b3 & x6);
			uint4 lt = b1 & x5;
			uint4 l0 = (b0 & x4) ^ lt;
			uint4 l1 = lt ^ (b0 & x5) ^ (b1 & x4);
			uint4 y0 = x4 ^ x6;
			uint4 y1 = x5 ^ x7;
			uint4 mt = z1 & y1;
			x4 = h1 ^ l0;
			x5 = h0 ^ h1 ^ l1;
			x6 = (z0 & y0) ^ mt ^ l0;
			x7 = mt ^ (z0 & y1) ^ (z1 & y0) ^ l1;
		}

		{
			uint4 ht = b3 & a3;
			uint4 h0 = (b2 & a2) ^ ht;
			uint4 h1 = ht ^ (b2 & a3) ^ (b3 & a2);
			uint4 lt = b1 & a1;
			uint4 l0 = (b0 & a0) ^ lt;
			uint4 l1 = lt ^ (b0 & a1) ^ (b1 & a0);
			uint4 y0 = a0 ^ a2;
			uint4 y1 = a1 ^ a3;
			uint4 mt = z1 & y1;
			x0 = h1 ^ l0;
			x1 = h0 ^ h1 ^ l1;
			x2 = (z0 & y0) ^ mt ^ l0;
			x3 = mt ^ (z0 & y1) ^ (z1 & y0) ^ l1;
		}
	}

	/* Inverse Isomorphic Mapping */
	a0 = x0 ^ x2 ^ x4 ^ x5 ^ x6;
	a1 = x4 ^ x5;
	a2 = x1 ^ x2 ^ x3 ^ x4 ^ x7;
	a3 = x1 ^ x2 ^ x3 ^ x4 ^ x5;
	b0 = x1 ^ x2 ^ x4 ^ x5 ^ x6;
	b1 = x1 ^ x5 ^ x6;
	b2 = x2 ^ x6;
	b3 = x1 ^ x5 ^ x6 ^ x7;

	/* s-box */
	dst[baseId + 0] = ~(a0 ^ b0 ^ b1 ^ b2 ^ b3);
	dst[baseId + 1] = ~(a0 ^ a1 ^ b1 ^ b2 ^ b3);
	dst[baseId + 2] = a0 ^ a1 ^ a2 ^ b2 ^ b3;
	dst[baseId + 3] = a0 ^ a1 ^ a2 ^ a3 ^ b3;
	dst[baseId + 4] = a0 ^ a1 ^ a2 ^ a3 ^ b0;
	dst[baseId + 5] = ~(a1 ^ a2 ^ a3 ^ b0 ^ b1);
	dst[baseId + 6] = ~(a2 ^ a3 ^ b0 ^ b1 ^ b2);
	dst[baseId + 7] = a3 ^ b0 ^ b1 ^ b2 ^ b3;
}

uint4 bitslice (__local uint* input, uint localId)
{
	uint k = localId >> 5;
	uint j = localId & 0x1F;
	uint x0 = ((input[k +   0] >> j) & 1) | (((input[k +   4] >> j) & 1) << 1) |
		(((input[k +   8] >> j) & 1) << 2) | (((input[k +  12] >> j) & 1) << 3) |
		(((input[k +  16] >> j) & 1) << 4) | (((input[k +  20] >> j) & 1) << 5) |
		(((input[k +  24] >> j) & 1) << 6) | (((input[k +  28] >> j) & 1) << 7) |
		(((input[k +  32] >> j) & 1) << 8) | (((input[k +  36] >> j) & 1) << 9) |
		(((input[k +  40] >> j) & 1) << 10) | (((input[k +  44] >> j) & 1) << 11) |
		(((input[k +  48] >> j) & 1) << 12) | (((input[k +  52] >> j) & 1) << 13) |
		(((input[k +  56] >> j) & 1) << 14) | (((input[k +  60] >> j) & 1) << 15) |
		(((input[k +  64] >> j) & 1) << 16) | (((input[k +  68] >> j) & 1) << 17) |
		(((input[k +  72] >> j) & 1) << 18) | (((input[k +  76] >> j) & 1) << 19) |
		(((input[k +  80] >> j) & 1) << 20) | (((input[k +  84] >> j) & 1) << 21) |
		(((input[k +  88] >> j) & 1) << 22) | (((input[k +  92] >> j) & 1) << 23) |
		(((input[k +  96] >> j) & 1) << 24) | (((input[k + 100] >> j) & 1) << 25) |
		(((input[k + 104] >> j) & 1) << 26) | (((input[k + 108] >> j) & 1) << 27) |
		(((input[k + 112] >> j) & 1) << 28) | (((input[k + 116] >> j) & 1) << 29) |
		(((input[k + 120] >> j) & 1) << 30) | (((input[k + 124] >> j) & 1) << 31);
	uint x1 = ((input[k + 128] >> j) & 1) | (((input[k + 132] >> j) & 1) << 1) |
		(((input[k + 136] >> j) & 1) << 2) | (((input[k + 140] >> j) & 1) << 3) |
		(((input[k + 144] >> j) & 1) << 4) | (((input[k + 148] >> j) & 1) << 5) |
		(((input[k + 152] >> j) & 1) << 6) | (((input[k + 156] >> j) & 1) << 7) |
		(((input[k + 160] >> j) & 1) << 8) | (((input[k + 164] >> j) & 1) << 9) |
		(((input[k + 168] >> j) & 1) << 10) | (((input[k + 172] >> j) & 1) << 11) |
		(((input[k + 176] >> j) & 1) << 12) | (((input[k + 180] >> j) & 1) << 13) |
		(((input[k + 184] >> j) & 1) << 14) | (((input[k + 188] >> j) & 1) << 15) |
		(((input[k + 192] >> j) & 1) << 16) | (((input[k + 196] >> j) & 1) << 17) |
		(((input[k + 200] >> j) & 1) << 18) | (((input[k + 204] >> j) & 1) << 19) |
		(((input[k + 208] >> j) & 1) << 20) | (((input[k + 212] >> j) & 1) << 21) |
		(((input[k + 216] >> j) & 1) << 22) | (((input[k + 220] >> j) & 1) << 23) |
		(((input[k + 224] >> j) & 1) << 24) | (((input[k + 228] >> j) & 1) << 25) |
		(((input[k + 232] >> j) & 1) << 26) | (((input[k + 236] >> j) & 1) << 27) |
		(((input[k + 240] >> j) & 1) << 28) | (((input[k + 244] >> j) & 1) << 29) |
		(((input[k + 248] >> j) & 1) << 30) | (((input[k + 252] >> j) & 1) << 31);
	uint x2 = ((input[k + 256] >> j) & 1) | (((input[k + 260] >> j) & 1) << 1) |
		(((input[k + 264] >> j) & 1) << 2) | (((input[k + 268] >> j) & 1) << 3) |
		(((input[k + 272] >> j) & 1) << 4) | (((input[k + 276] >> j) & 1) << 5) |
		(((input[k + 280] >> j) & 1) << 6) | (((input[k + 284] >> j) & 1) << 7) |
		(((input[k + 288] >> j) & 1) << 8) | (((input[k + 292] >> j) & 1) << 9) |
		(((input[k + 296] >> j) & 1) << 10) | (((input[k + 300] >> j) & 1) << 11) |
		(((input[k + 304] >> j) & 1) << 12) | (((input[k + 308] >> j) & 1) << 13) |
		(((input[k + 312] >> j) & 1) << 14) | (((input[k + 316] >> j) & 1) << 15) |
		(((input[k + 320] >> j) & 1) << 16) | (((input[k + 324] >> j) & 1) << 17) |
		(((input[k + 328] >> j) & 1) << 18) | (((input[k + 332] >> j) & 1) << 19) |
		(((input[k + 336] >> j) & 1) << 20) | (((input[k + 340] >> j) & 1) << 21) |
		(((input[k + 344] >> j) & 1) << 22) | (((input[k + 348] >> j) & 1) << 23) |
		(((input[k + 352] >> j) & 1) << 24) | (((input[k + 356] >> j) & 1) << 25) |
		(((input[k + 360] >> j) & 1) << 26) | (((input[k + 364] >> j) & 1) << 27) |
		(((input[k + 368] >> j) & 1) << 28) | (((input[k + 372] >> j) & 1) << 29) |
		(((input[k + 376] >> j) & 1) << 30) | (((input[k + 380] >> j) & 1) << 31);
	uint x3 = ((input[k + 384] >> j) & 1) | (((input[k + 388] >> j) & 1) << 1) |
		(((input[k + 392] >> j) & 1) << 2) | (((input[k + 396] >> j) & 1) << 3) |
		(((input[k + 400] >> j) & 1) << 4) | (((input[k + 404] >> j) & 1) << 5) |
		(((input[k + 408] >> j) & 1) << 6) | (((input[k + 412] >> j) & 1) << 7) |
		(((input[k + 416] >> j) & 1) << 8) | (((input[k + 420] >> j) & 1) << 9) |
		(((input[k + 424] >> j) & 1) << 10) | (((input[k + 428] >> j) & 1) << 11) |
		(((input[k + 432] >> j) & 1) << 12) | (((input[k + 436] >> j) & 1) << 13) |
		(((input[k + 440] >> j) & 1) << 14) | (((input[k + 444] >> j) & 1) << 15) |
		(((input[k + 448] >> j) & 1) << 16) | (((input[k + 452] >> j) & 1) << 17) |
		(((input[k + 456] >> j) & 1) << 18) | (((input[k + 460] >> j) & 1) << 19) |
		(((input[k + 464] >> j) & 1) << 20) | (((input[k + 468] >> j) & 1) << 21) |
		(((input[k + 472] >> j) & 1) << 22) | (((input[k + 476] >> j) & 1) << 23) |
		(((input[k + 480] >> j) & 1) << 24) | (((input[k + 484] >> j) & 1) << 25) |
		(((input[k + 488] >> j) & 1) << 26) | (((input[k + 492] >> j) & 1) << 27) |
		(((input[k + 496] >> j) & 1) << 28) | (((input[k + 500] >> j) & 1) << 29) |
		(((input[k + 504] >> j) & 1) << 30) | (((input[k + 508] >> j) & 1) << 31);
	return (uint4)(x0, x1, x2, x3);
}

void unbitslice (__local uint4* buf, __global uint* output, uint offset, uint localId)
{
	uint k = localId >> 5;
	uint j = localId & 0x1F;
	uint x0 = 0, x1 = 0, x2 = 0, x3 = 0;
	switch (k) {
	case 0:
		for (int i = 0; i < 32; i ++) x0 |= ((buf[i].s0 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x1 |= ((buf[i + 32].s0 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x2 |= ((buf[i + 64].s0 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x3 |= ((buf[i + 96].s0 >> j) & 1) << i;
		break;
	case 1:
		for (int i = 0; i < 32; i ++) x0 |= ((buf[i].s1 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x1 |= ((buf[i + 32].s1 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x2 |= ((buf[i + 64].s1 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x3 |= ((buf[i + 96].s1 >> j) & 1) << i;
		break;
	case 2:
		for (int i = 0; i < 32; i ++) x0 |= ((buf[i].s2 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x1 |= ((buf[i + 32].s2 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x2 |= ((buf[i + 64].s2 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x3 |= ((buf[i + 96].s2 >> j) & 1) << i;
		break;
	case 3:
		for (int i = 0; i < 32; i ++) x0 |= ((buf[i].s3 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x1 |= ((buf[i + 32].s3 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x2 |= ((buf[i + 64].s3 >> j) & 1) << i;
		for (int i = 0; i < 32; i ++) x3 |= ((buf[i + 96].s3 >> j) & 1) << i;
		break;
	}
	output[(offset + localId) * 4] = x0;
	output[(offset + localId) * 4 + 1] = x1;
	output[(offset + localId) * 4 + 2] = x2;
	output[(offset + localId) * 4 + 3] = x3;
}

__kernel 
void encrypt (__global uint* input,
              const __global uint* bitsliceKey,
              __local    uint4* tmp0,
              __local    uint4* tmp1,
              __local    uint* tmp2
)
{
	uint groupId = get_group_id(0);
	uint localId = get_local_id(0);
	uint offset = groupId * BLOCK_BITS;

	tmp2[localId * 4 + 0] = input[(offset + localId) * 4 + 0];
	tmp2[localId * 4 + 1] = input[(offset + localId) * 4 + 1];
	tmp2[localId * 4 + 2] = input[(offset + localId) * 4 + 2];
	tmp2[localId * 4 + 3] = input[(offset + localId) * 4 + 3];
	barrier (CLK_LOCAL_MEM_FENCE);
	tmp0[localId] = bitslice (tmp2, localId) ^ bitsliceKey[localId];
	barrier (CLK_LOCAL_MEM_FENCE);
	
	for (uint i = 1; i < 10; i ++) {
		subBytes (tmp0, tmp1, localId);
		barrier (CLK_LOCAL_MEM_FENCE);
		tmp0[localId] = mixColumns (tmp1, localId) ^ bitsliceKey[i * BLOCK_BITS + localId];
		barrier (CLK_LOCAL_MEM_FENCE);
	}
	subBytes (tmp0, tmp1, localId);
	barrier (CLK_LOCAL_MEM_FENCE);
	uint newId = shiftRows1 (localId);
	tmp0[newId] = tmp1[localId] ^ bitsliceKey[10 * BLOCK_BITS + newId];
	barrier (CLK_LOCAL_MEM_FENCE);
	unbitslice (tmp0, input, offset, localId);
}

__kernel 
void bitslice_key (const __global uchar* expandedKey,
                   __global   uint*  bitsliceKey)
{
	uint id = get_global_id (0);
	uint k = id >> 3;
	uint j = id & 0x7;
	bitsliceKey[id] = ((expandedKey[k] >> j) & 1) == 0 ? 0 : 0xffffffff;
}
