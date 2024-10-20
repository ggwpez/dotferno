import { TypeormDatabase, Store } from '@subsquid/typeorm-store'
import assert from 'assert'

import { processor, ProcessorContext } from './processor'
import { Burn } from './model'
import { events } from './types'
import { Balance } from './types/v0'
import { totalIssuance } from './types/balances/storage'

processor.run(new TypeormDatabase({ supportHotBlocks: true }), async (ctx) => {
    let aggregated;
    let last = await ctx.store.get(Burn, {order: {id: 'DESC'}, where: { }});

    if (!last) {
        aggregated = BigInt(0);
        console.log('No previous aggregation record found, starting from 0');
    } else {
        aggregated = last.aggregated;
    }

    let burns: Burn[] = getBurns(ctx, aggregated)
    await ctx.store.save(burns)
})

function getBurns(ctx: ProcessorContext<Store>, aggregated: bigint): Burn[] {
    let burns: Burn[] = []

    for (let block of ctx.blocks) {
        const ti = totalIssuance.v0.get(block.header)

        for (let event of block.events) {
            if (event.name != events.treasury.burnt.name &&
                event.name != events.balances.burned.name &&
                event.name != events.balances.minted.name
            ) {
                continue
            }

            let burned: bigint = 0n;

            if (events.balances.burned.v9420.is(event)) {
                let { amount } = events.balances.burned.v9420.decode(event)
                burned += amount
            } else if (events.treasury.burnt.v0.is(event)) {
                let amount = events.treasury.burnt.v0.decode(event)
                burned += amount
            } else if (events.treasury.burnt.v9170.is(event)) {
                let { burntFunds } = events.treasury.burnt.v9170.decode(event)
                burned += burntFunds
            } else if (events.balances.minted.v9420.is(event)) {
                let { amount } = events.balances.minted.v9420.decode(event)
                burned -= amount
            } else {
                throw new Error('Unsupported spec')
            }

            assert(block.header.timestamp, `Got an undefined timestamp at block ${block.header.height}`)

            aggregated += burned
            burns.push(new Burn({
                id: event.id,
                blockNumber: block.header.height,
                timestamp: new Date(block.header.timestamp),
                amount: burned,
                aggregated
            }))
        }
    }
    return burns
}
