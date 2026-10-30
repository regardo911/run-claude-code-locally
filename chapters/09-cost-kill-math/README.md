# Chapter 9: your break-even month

```bash
./break-even.sh --cloud <your monthly bill> --electricity <your estimate> --hardware <what you bought, or 0> [--months <how long you'll use it>]
```

Every number is yours, and the script has no defaults. Before you run it:

1. Cloud: average your last few months of real charges, subscription plus any usage billing. Read it off your statements.
2. Electricity: your estimate for a month of running models locally. A few dollars for most people; more if your rates or your usage are high.
3. Hardware: what you bought for this. `0` if you run on a machine you already own.
4. Months (optional): how long you'll use that hardware, if you want to see it spread across the bill like the book's step 2.

The script prints your monthly cloud and local cost, what you save each month, the month the hardware has paid for itself, and your first-year net. When cloud costs no more than electricity, it says local never wins on cost alone. That's chapter 10's cue: maybe privacy is your reason.

One change from the print: payback here is `hardware / (cloud - electricity)`. The book's steps 4 and 5 take the hardware off twice, which roughly doubles the wait on its own GPU example. [BOOK-FIXES.md](../../BOOK-FIXES.md#chapter-9-the-calculator-counts-the-hardware-twice-ch0951-57) has the arithmetic.

Then decide which of the chapter's three setups is yours: full-local, hybrid, or a free hosted route. Check the free tiers' current limits on their own sites.
