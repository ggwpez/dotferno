import {sts, Block, Bytes, Option, Result, EventType, RuntimeCtx} from '../support'
import * as v9420 from '../v9420'

export const burned =  {
    name: 'Balances.Burned',
    /**
     * Some amount was burned from an account.
     */
    v9420: new EventType(
        'Balances.Burned',
        sts.struct({
            who: v9420.AccountId32,
            amount: sts.bigint(),
        })
    ),
}
