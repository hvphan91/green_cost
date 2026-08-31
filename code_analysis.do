cd "C..."
capture log close 
log using "analysis_log", replace text


import excel wb_data2, firstrow case(lower) clear

for var inc80 inc90 inc99 wea80 wea90 wea99: replace X = X*100

*** drop missing values and shorter panels 
foreach var in recon reout{
	misstable patterns tco gdpc pop urb trd ind `var' inc80 inc90 inc99, freq
	missings tag tco gdpc pop urb trd ind `var' inc80 inc90 inc99, gen(mc_`var')
}

drop if mc_recon > 0

gen inclvl = 1
replace inclvl = 2 if incomelevel == "Upper middle income"
replace inclvl = 3 if incomelevel == "Lower middle income"
replace inclvl = 4 if incomelevel == "Low income"
replace inclvl = . if incomelevel == "Not classified"

label define inclvl 1 "High" 2 "Upper-middle" 3 "Lower-middle" 4 "Low"
label values inclvl inclvl

//drop if mc_reout > 0
preserve

drop if year > 2019
bysort id: egen cfreq = count(id)
drop if cfreq < 20
save sample_m20.dta, replace
restore

preserve
drop if year > 2019
bysort id: egen cfreq = count(id)
drop if cfreq < 30
save sample_m30.dta, replace
restore

preserve
drop if year > 2021
bysort id: egen cfreq = count(id)
drop if cfreq < 10
save sample_m10.dta, replace
restore

preserve
drop if year > 2021
bysort id: egen cfreq = count(id)
drop if cfreq < 5
save sample_big.dta, replace
restore


*** import data
use sample_big.dta, clear

sum tco elcon euse inc80 inc90 inc99 wea80 wea90 wea99 recon gdpc pop urb trd ind 

gen tcoc = tco / pop * 1000000
gen reprdt = reprd + rehyd

gen elcont = elcon * pop
gen euset = euse * pop

for var tco tcoc elcon elcont euse euset gdpc pop urb trd ind reout reprd reprdt recon nuke ffprd ffcon enat enaru enaub inc80 inc90 inc99 wea80 wea90 wea99: gen lX = ln(X+0.001)

*** grand-mean centered and group mean centered models
* mean-centering
for var lgdpc linc80 linc90 linc99 lwea80 lwea90 lwea99 lreout lreprd lreprdt lrecon: sum X \ gen XGm = X - r(mean)
//for var : by id: egen Xmean = mean(X) \ by id: gen Xgm = X - Xmean 

encode id, gen(cid)
xtset cid year


*** some graphs
** Title: "Average per capita emissions of top 10% income and of total population across national income levels"
graph hbar car90 carall if year == 1990 | year == 2000 | year == 2019, over(inclvl) over(year) ytitle("Tons of CO2 equivalent per capita emissions", margin(vsmall)) ylabel(0(5)30, labsize(small) nogrid) legend(label(1 "Top 10%") label(2 "Total Population")) blabel(total, format(%10.2f) size(vsmall)) scheme(s1mono)

preserve
collapse gdpc car90 carall ghgall ghg90 cghgall cghg90, by(id)
twoway scatter car90 gdpc if car90 > 0, name(car_graph, replace) || lfit car90 gdpc if car90 > 0 || scatter carall gdpc if carall > 0, msymbol(S) || lfit carall gdpc if carall > 0
twoway scatter ghg90 gdpc if ghg90 > 0, name(ghg_graph, replace) || lfit ghg90 gdpc if ghg90 > 0 || scatter ghgall gdpc if ghgall > 0, msymbol(S) || lfit ghgall gdpc if ghgall > 0
twoway scatter cghg90 gdpc if cghg90 > 0, name(cghg_graph, replace) || lfit cghg90 gdpc if cghg90 > 0 || scatter cghgall gdpc if cghgall > 0, msymbol(S) || lfit cghgall gdpc if cghgall > 0

restore



*** analysis

*** no interaction models
foreach var in linc80Gm linc90Gm linc99Gm{
	quiet xtreg ltco c.lreconGm c.`var' lgdpcGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store nia_`var'
	di e(N_g)
	quiet xtreg ltco l.ltco c.lreconGm c.`var' lgdpcGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store nial_`var'
	di e(N_g)
	nlcom _b[lreconGm]/(1-_b[L.ltco])
}

esttab nia_linc80Gm nia_linc90Gm nia_linc99Gm nial_linc80Gm nial_linc90Gm nial_linc99Gm using "new_draft/table2.csv", obslast l b(3) se(3) noomit ar2 drop(*.year) nonum o(L.ltco lreconGm lgdpcGm linc80Gm linc90Gm linc99Gm) star(+ 0.1 * 0.05 ** 0.01 *** 0.001) replace



*** full interaction, income
foreach var in linc80Gm linc90Gm linc99Gm {
	quiet xtreg ltco c.`var'##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store aia_`var'
	di e(N_g)
	quiet xtreg ltco l.ltco c.`var'##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store aial_`var'
	di e(N_g)
	nlcom _b[lreconGm]/(1-_b[L.ltco])
	nlcom _b[c.lreconGm#c.lgdpcGm]/(1-_b[L.ltco])
	nlcom _b[c.lreconGm#c.`var']/(1-_b[L.ltco])
	nlcom _b[c.lgdpcGm#c.`var']/(1-_b[L.ltco])
	nlcom _b[c.lreconGm#c.lgdpcGm#c.`var']/(1-_b[L.ltco])
}

esttab aia_linc80Gm aia_linc90Gm aia_linc99Gm aial_linc80Gm aial_linc90Gm aial_linc99Gm using "new_draft/table3.csv", obslast l b(3) se(3) noomit ar2 drop(*.year) nonum o(L.ltco lreconGm lgdpcGm linc80Gm linc90Gm linc99Gm c.lreconGm#c.lgdpcGm c.lreconGm#c.linc80Gm c.lreconGm#c.linc90Gm c.lreconGm#c.linc99Gm c.lgdpcGm#c.linc80Gm c.lgdpcGm#c.linc90Gm c.lgdpcGm#c.linc99Gm c.lreconGm#c.linc80Gm#c.lgdpcGm c.lreconGm#c.linc90Gm#c.lgdpcGm c.lreconGm#c.linc99Gm#c.lgdpcGm) star(+ 0.1 * 0.05 ** 0.01 *** 0.001) replace


*** full intreaction with elcon and ffcon
foreach var in linc80Gm linc90Gm linc99Gm {
	quiet xtreg ltco c.`var'##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store b_`var'
	di e(N_g)
	quiet xtreg ltco c.`var'##c.lgdpcGm##c.lreconGm lffcon lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store robff_`var'
	di e(N_g)
	quiet xtreg ltco c.`var'##c.lgdpcGm##c.lreconGm lelcon lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store robel_`var'
	di e(N_g)
}

esttab b_linc80Gm b_linc90Gm b_linc99Gm robff_linc80Gm robff_linc90Gm robff_linc99Gm robel_linc80Gm robel_linc90Gm robel_linc99Gm using "new_draft/table5.csv", obslast l b(3) se(3) noomit ar2 drop(*.year) nonum o(lreconGm lgdpcGm linc80Gm linc90Gm linc99Gm c.lreconGm#c.lgdpcGm c.lreconGm#c.linc80Gm c.lreconGm#c.linc90Gm c.lreconGm#c.linc99Gm c.lgdpcGm#c.linc80Gm c.lgdpcGm#c.linc90Gm c.lgdpcGm#c.linc99Gm c.lreconGm#c.linc80Gm#c.lgdpcGm c.lreconGm#c.linc90Gm#c.lgdpcGm c.lreconGm#c.linc99Gm#c.lgdpcGm lffcon lelcon) star(+ 0.1 * 0.05 ** 0.01 *** 0.001) replace


foreach var in linc80Gm linc90Gm linc99Gm {
	quiet xtreg ltco l.ltco c.`var'##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store b_`var'
	di e(N_g)
	quiet xtreg ltco l.ltco c.`var'##c.lgdpcGm##c.lreconGm lffcon lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store robff_`var'
	di e(N_g)
	quiet xtreg ltco l.ltco c.`var'##c.lgdpcGm##c.lreconGm lelcon lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store robel_`var'
	di e(N_g)
}

esttab b_linc80Gm b_linc90Gm b_linc99Gm robff_linc80Gm robff_linc90Gm robff_linc99Gm robel_linc80Gm robel_linc90Gm robel_linc99Gm using "new_draft/table6.csv", obslast l b(3) se(3) noomit ar2 drop(*.year) nonum o(L.ltco lreconGm lgdpcGm linc80Gm linc90Gm linc99Gm c.lreconGm#c.lgdpcGm c.lreconGm#c.linc80Gm c.lreconGm#c.linc90Gm c.lreconGm#c.linc99Gm c.lgdpcGm#c.linc80Gm c.lgdpcGm#c.linc90Gm c.lgdpcGm#c.linc99Gm c.lreconGm#c.linc80Gm#c.lgdpcGm c.lreconGm#c.linc90Gm#c.lgdpcGm c.lreconGm#c.linc99Gm#c.lgdpcGm lffcon lelcon) star(+ 0.1 * 0.05 ** 0.01 *** 0.001) replace


/// illustration for linc90, contemp var. (Fig 2)
preserve 
collapse lgdpcGm linc90Gm lreconGm inclvl, by(id)
twoway scatter linc90Gm lgdpcGm, xtitle("GDP/capita", margin(small)) ytitle("INE (top 10%)", margin(small)) xlabel(-3(1)3.5, labsize(small) nogrid) ylabel(-0.6(0.2)0.4, labsize(small) nogrid) graphregion(margin(medium)) plotregion(margin(zero)) mlabel(id inclvl)
graph save scatterp, replace
restore

preserve
serset clear
graph use scatterp.gph
serset 0
serset use, clear
dataex, count(180)
restore

sum lgdpcGm linc90Gm

qui xtreg ltco c.linc90Gm##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
qui margins, dydx(lreconGm) at(lgdpcGm=(-3(1)3) linc90Gm=(-0.6(0.15)0.45)) post
esttab using "new_draft/margin_table.csv", b(3) se(3) star(+ 0.1 * 0.05 ** 0.01 *** 0.001) mtitles("Margins") replace

qui xtreg ltco c.linc90Gm##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid) 
qui margins, dydx(lreconGm) at(lgdpcGm=(-3.2(0.4)3.2) linc90Gm=(-0.65(0.05)0.45))
_marg_save, saving(temp, replace)

preserve
use temp, clear

*copy code input

sum _margin

gen pos = 3
replace pos = 12 if id == "GBR" | id == "JPN" | id == "OMN" | id == "NZL" | id == "BMU" 
replace pos = 10 if id == "NZL" | id == "LUX" 
replace pos = 9 if id == "BEL" | id == "FIN" | id == "COD" | id == "TCD"
replace pos = 7 if id == "SWE" | id == "GRC" | id == "MLI" | id == "SAU"
replace pos = 6 if id == "BRN" | id == "PLW" | id == "PYF" | id == "POL"
replace pos = 5 if id == "KWT"
replace pos = 4 if id == "DEU" | id == "ARE" | id == "ABW" 
replace pos = 2 if id == "DNK" | id == "BHR" | id == "CZE" | id == "BFA" | id == "UGA" | id == "ERI" | id == "URY" | id == "QAT"

twoway contour _margin _at1 _at2, ccut(-0.6(0.1)0.2) sc(lime) ec(red) xtitle("GDP/capita", margin(vsmall)) ytitle("INE (top 10%)", margin(small)) xlabel(-3.2(0.8)3.2, labsize(small) nogrid) ylabel(-0.6(0.15)0.45, labsize(small) nogrid) ztitle("Marginal effect of RE", margin(small)) name(marginscon, replace) || contourline _pvalue _at1 _at2, plegend(off) colorlines scolor(black) ecolor(black) crule(linear) clw(vthin medium) ccut(.05 .01) plotregion(margin(zero)) note("Contour lines (black) indicate significant marginal effect (5%, 1%)" "Decreasing thickness indicates lower p-value" "All variables grand-mean centered") graphregion(color(white) margin(medium)) || scatter linc90Gm lgdpcGm if inclvl == 1, msymbol(S) mlabel(id) mlabsize(vsmall) mlabv(pos) mcol(black%50) msize(vsmall) mlabcol(black) mlabsize(tiny) mlabg(0.75pt) || scatter linc90Gm lgdpcGm if inclvl == 4, msymbol(T) mlabel(id) mlabsize(vsmall) mlabv(pos) mcol(gray) msize(vsmall) mlabcol(black) mlabsize(tiny) mlabg(0.75pt) || scatter linc90Gm lgdpcGm if inclvl == 2 | inclvl == 3, msymbol(Oh) mlcol(%30) msize(vsmall) leg(size(small) rows(1) label(1 "High-income") label(2 "Low-income") label(3 "Others") region(style(none)) bmargin(none))

graph export Contour_con.png, replace

restore

/// illustration for linc90, contemp var. (Fig 3)

xtreg ltco c.linc90Gm##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
margins, dydx(lreconGm) at(lgdpcGm=(-3(1)3) linc90Gm=-0.6)
marginsplot, scheme(s1mono) recastci(rarea) ciopt(color(%20) lcolor(%0)) ylabel(, nogrid) plotregion(lcolor(black) lwidth(medium)) graphregion(color(white) margin(medium)) yline(0) title("Top 10% income = 23.5% (min)") xtitle("GDP/capita (grand-mean centered)", margin(small)) ytitle("") name(a, replace)
margins, dydx(lreconGm) at(lgdpcGm=(-3(1)3) linc90Gm=0)
marginsplot, scheme(s1mono) recastci(rarea) ciopt(color(%20) lcolor(%0)) ylabel(, nogrid) plotregion(lcolor(black) lwidth(medium)) graphregion(color(white) margin(medium)) yline(0) title("Top 10% income = 45.8% (mean)") xtitle("GDP/capita (grand-mean centered)", margin(small)) ytitle("") name(b, replace)
margins, dydx(lreconGm) at(lgdpcGm=(-3(1)3) linc90Gm=0.45)
marginsplot, scheme(s1mono) recastci(rarea) ciopt(color(%20) lcolor(%0)) ylabel(, nogrid) plotregion(lcolor(black) lwidth(medium)) graphregion(color(white) margin(medium)) yline(0) title("Top 10% income = 69.1% (max)") xtitle("GDP/capita (grand-mean centered)", margin(small)) ytitle("") name(c, replace)
graph combine a b c, rows(1) ycommon xsize(2) ysize(1)


/// illustration for linc90, LDV
qui xtreg ltco l.ltco c.linc90Gm##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid) 
qui margins, dydx(lreconGm) at(lgdpcGm=(-3.2(0.4)3.2) linc90Gm=(-0.65(0.05)0.45)) force
_marg_save, saving(temp, replace)

preserve
use temp, clear

*copy code input

sum _margin

gen pos = 3
replace pos = 12 if id == "GBR" | id == "JPN" | id == "OMN" | id == "NZL"
replace pos = 10 if id == "NZL"
replace pos = 9 if id == "BEL" | id == "FIN" | id == "COD" | id == "TCD"
replace pos = 7 if id == "SWE" | id == "GRC" | id == "MLI"
replace pos = 6 if id == "BRN" | id == "PLW" | id == "POL" | id == "SYC" | id == "PRT"
replace pos = 5 if id == "KWT" | id == "BMU"
replace pos = 4 if id == "DEU" | id == "ARE" | id == "SAU" | id == "ABW" 
replace pos = 2 if id == "DNK" | id == "BHR" | id == "GBR" | id == "CZE" | id == "BFA" | id == "UGA" | id == "ERI" | id == "URY" | id == "PYF"

twoway contour _margin _at2 _at3, ccut(-0.24(0.03)0.08) sc(lime) ec(red) xtitle("GDP/capita", margin(vsmall)) ytitle("INE (top 10%)", margin(small)) xlabel(-3.2(0.8)3.2, labsize(small) nogrid) ylabel(-0.6(0.15)0.45, labsize(small) nogrid) ztitle("Marginal effect of RE", margin(small)) name(marginsldv, replace) || contourline _pvalue _at2 _at3, plegend(off) colorlines scolor(black) ecolor(black) crule(linear) clw(vthin medium) ccut(.05 .01) plotregion(margin(zero)) note("Contour lines (black) indicate significant marginal effect (5%, 1%)" "Decreasing thickness indicates lower p-value" "All variables grand-mean centered") graphregion(color(white) margin(medium)) || scatter linc90Gm lgdpcGm if inclvl == 1, msymbol(S) mlabel(id) mlabsize(vsmall) mlabv(pos) mcol(black%50) msize(vsmall) mlabcol(black) mlabsize(tiny) mlabg(0.75pt) || scatter linc90Gm lgdpcGm if inclvl == 4, msymbol(T) mlabel(id) mlabsize(vsmall) mlabv(pos) mcol(gray) msize(vsmall) mlabcol(black) mlabsize(tiny) mlabg(0.75pt) || scatter linc90Gm lgdpcGm if inclvl == 2 | inclvl == 3, msymbol(Oh) mlcol(%30) msize(vsmall) leg(size(small) rows(1) label(1 "High-income") label(2 "Low-income") label(3 "Others") region(style(none)) bmargin(none))

graph export Contour_ldv.png, replace

restore


*** wealth
foreach var in lwea80Gm lwea90Gm lwea99Gm {
	quiet xtreg ltco c.lreconGm c.`var' lgdpcGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store nia_`var'
	di e(N_g)
	quiet xtreg ltco l.ltco c.lreconGm c.`var' lgdpcGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store nial_`var'
	di e(N_g)
}

esttab nia_lwea80Gm nia_lwea90Gm nia_lwea99Gm nial_lwea80Gm nial_lwea90Gm nial_lwea99Gm using "xtregwea.csv", obslast l b(3) se(3) noomit ar2 drop(*.year) nonum o(lreconGm lgdpcGm lwea80Gm lwea90Gm lwea99Gm) star(+ 0.1 * 0.05 ** 0.01 *** 0.001) replace


foreach var in lwea80Gm lwea90Gm lwea99Gm {
	quiet xtreg ltco c.`var'##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store aia_`var'
	di e(N_g)
	quiet xtreg ltco l.ltco c.`var'##c.lgdpcGm##c.lreconGm lind lpop lurb ltrd i.year, fe vce(cluster cid)
	est store aial_`var'
	di e(N_g)
}

esttab aia_lwea80Gm aia_lwea90Gm aia_lwea99Gm aial_lwea80Gm aial_lwea90Gm aial_lwea99Gm using "xtregweai.csv", obslast l b(3) se(3) noomit ar2 drop(*.year) nonum o(lreconGm lgdpcGm lwea80Gm lwea90Gm lwea99Gm c.lreconGm#c.lgdpcGm c.lreconGm#c.lwea80Gm c.lreconGm#c.lwea90Gm c.lreconGm#c.lwea99Gm c.lgdpcGm#c.lwea80Gm c.lgdpcGm#c.lwea90Gm c.lgdpcGm#c.lwea99Gm c.lreconGm#c.lwea80Gm#c.lgdpcGm c.lreconGm#c.lwea90Gm#c.lgdpcGm c.lreconGm#c.lwea99Gm#c.lgdpcGm) star(+ 0.1 * 0.05 ** 0.01 *** 0.001) replace



