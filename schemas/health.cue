package schemas

#HealthMetrics: {
    person: string
    week: string & =~"^[0-9]{4}-W[0-9]{2}$"

    sleep: {
        score: number & >=0 & <=100
        duration_hours: number & >=0 & <=24
        efficiency: number & >=0 & <=100
    }

    recovery: {
        score: number & >=0 & <=100
        hrv: number & >=0
        rhr: number & >=0
    }

    strain: {
        average: number & >=0 & <=21
        max: number & >=0 & <=21
    }
}
