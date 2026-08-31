cd "..."

/// income share
wid, indicators(sptinc) perc(p80p100 p90p100 p99p100) years(1990/2024) age(992) pop(j) clear
export excel using "ine_inc.xlsx", replace

wid, indicators(shweal) perc(p80p100 p90p100 p99p100) years(1990/2024) age(992) pop(j) clear
export excel using "ine_wea.xlsx", replace

// emissions share
wid, indicators(lpfcar) perc(p90p100 p0p50 p50p90) years(1990/2024) clear
export excel using "car_dis.xlsx", replace

wid, indicators(lpfghg) perc(p90p100 p0p50 p50p90) years(1990/2024) clear
export excel using "ghg_dis.xlsx", replace

wid, indicators(lcfghg) perc(p90p100 p0p50 p50p90) years(1990/2024) clear
export excel using "cghg_dis.xlsx", replace
