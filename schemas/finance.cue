package schemas

#Transaction: {
    date: string
    description: string
    amount: number
    category: string
    account: string
    tags?: [...string]
}

#FinancialSummary: {
    period: string
    income: number
    expenses: number
    savings_rate: number & >=-100 & <=100
    top_categories: [...#CategorySpend]
}

#CategorySpend: {
    category: string
    amount: number
    percent: number & >=0 & <=100
}
