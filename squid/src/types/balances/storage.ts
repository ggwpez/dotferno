import {sts, Block, Bytes, Option, Result, StorageType, RuntimeCtx} from '../support'
import * as v0 from '../v0'

export const totalIssuance =  {
    /**
     *  The total units issued in the system.
     */
    v0: new StorageType('Balances.TotalIssuance', 'Default', [], v0.Balance) as TotalIssuanceV0,
}

/**
 *  The total units issued in the system.
 */
export interface TotalIssuanceV0  {
    is(block: RuntimeCtx): boolean
    getDefault(block: Block): v0.Balance
    get(block: Block): Promise<(v0.Balance | undefined)>
}
