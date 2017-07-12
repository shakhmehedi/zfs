#!/bin/ksh -p
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2017, loli10K. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/no_space/enospc.cfg
. $STF_SUITE/tests/functional/cli_root/zpool_create/zpool_create.shlib

#
# DESCRIPTION:
#	ENOSPC is returned on pools with large physical block size and small
#	recordsize.
#
# STRATEGY:
#	1. Create a pool with property ashift=13 (8K block size)
#	2. Set property recordsize=512 and copies=3 on the root dataset
#	3. Write a file until the file system is full
#	4. Verify the return code is ENOSPC
#

verify_runnable "both"

function cleanup
{
	log_must zpool destroy $TESTPOOL1
	log_must rm -f $disk
}

log_onexit cleanup

log_assert "ENOSPC is returned on pools with large physical block size"

disk=$TEST_BASE_DIR/$FILEDISK0
# we need a device big enough to test this or failure will not trigger
size="512m"
log_must mkfile $size $disk

log_must zpool create $TESTPOOL1 -o ashift=13 $disk
log_must zfs set mountpoint=$TESTDIR $TESTPOOL1
log_must zfs set compression=off $TESTPOOL1
log_must zfs set recordsize=512 $TESTPOOL1
log_must zfs set copies=3 $TESTPOOL1

log_note "Writing file: $TESTFILE0 until ENOSPC."
file_write -o create -f $TESTDIR/$TESTFILE0 -b $BLOCKSZ \
    -c $NUM_WRITES -d $DATA
ret=$?

(( $ret != $ENOSPC )) && \
    log_fail "$TESTFILE0 returned: $ret rather than ENOSPC."

log_pass "ENOSPC returned as expected."