/*
 * Copyright (c) 2016, ARM Limited and Contributors. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of ARM nor the names of its contributors may be used
 * to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <arch.h>
#include <asm_macros.S>
#include <common_def.h>
#include <memctrl_v2.h>
#include <tegra_def.h>

#define TEGRA186_SMMU_CTX_SIZE		0x420

	.align 4
	.globl	tegra186_cpu_reset_handler

/* CPU reset handler routine */
func tegra186_cpu_reset_handler
	/*
	 * The TZRAM loses state during System Suspend. We use this
	 * information to decide if the reset handler is running after a
	 * System Suspend. Resume from system suspend requires restoring
	 * the entire state from TZDRAM to TZRAM.
	 */
	mov	x0, #BL31_BASE
	ldr	x0, [x0]
	cbnz	x0, boot_cpu

	/* resume from system suspend */
	mov	x0, #BL31_BASE
	adr	x1, __tegra186_cpu_reset_handler_end
	adr	x2, __tegra186_cpu_reset_handler_data
	ldr	x2, [x2, #8]

	/* memcpy16 */
m_loop16:
	cmp	x2, #16
	b.lt	m_loop1
	ldp	x3, x4, [x1], #16
	stp	x3, x4, [x0], #16
	sub	x2, x2, #16
	b	m_loop16
	/* copy byte per byte */
m_loop1:
	cbz	x2, boot_cpu
	ldrb	w3, [x1], #1
	strb	w3, [x0], #1
	subs	x2, x2, #1
	b.ne	m_loop1

boot_cpu:
	adr	x0, __tegra186_cpu_reset_handler_data
	ldr	x0, [x0]
	br	x0
endfunc tegra186_cpu_reset_handler

	/*
	 * Tegra186 reset data (offset 0x0 - 0x430)
	 *
	 * 0x000: secure world's entrypoint
	 * 0x008: BL31 size (RO + RW)
	 * 0x00C: SMMU context start
	 * 0x42C: SMMU context end
	 */

	.align 4
	.type	__tegra186_cpu_reset_handler_data, %object
	.globl	__tegra186_cpu_reset_handler_data
__tegra186_cpu_reset_handler_data:
	.quad	tegra_secure_entrypoint
	.quad	__BL31_END__ - BL31_BASE
	.rept	TEGRA186_SMMU_CTX_SIZE
	.quad	0
	.endr
	.size	__tegra186_cpu_reset_handler_data, \
		. - __tegra186_cpu_reset_handler_data

	.align 4
	.globl	__tegra186_cpu_reset_handler_end
__tegra186_cpu_reset_handler_end:
