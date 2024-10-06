import {sts, Block, Bytes, Option, Result, EventType, RuntimeCtx} from '../support'
import * as v0 from '../v0'

export const burnt =  {
    name: 'Treasury.Burnt',
    /**
     *  Some of our funds have been burnt.
     */
    v0: new EventType(
        'Treasury.Burnt',
        v0.Balance
    ),
    /**
     * Some of our funds have been burnt.
     */
    v9170: new EventType(
        'Treasury.Burnt',
        sts.struct({
            burntFunds: sts.bigint(),
        })
    ),
}
