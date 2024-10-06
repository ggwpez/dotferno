import {sts, Result, Option, Bytes, BitSequence} from './support'

export type Balance = bigint

export const Balance = sts.bigint()
