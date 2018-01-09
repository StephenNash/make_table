/*
Hello Daniel!

Make a table of proportions, means and medians across multiple groups

Written by: Stephen Nash
Date created: 5 December 2017

*/

/* Program WRITE_LINES
	Writes basic (demographic) information to a table, by (treatment) arm
	Syntax is
		write_lines list_of_row_variables , colvar(name of column variable) fhandle(file handle) [total]
*/

cap prog drop write_lines
prog define write_lines , rclass //
	version 14.2
	syntax varlist [if] , colvar(varname) fhandle(string) [TOTal]
	*
	preserve
	*keep `if'
		foreach demo_name of varlist `varlist' {
			local label_name: variable label `demo_name'
			* How many columns are there? We'll need this for later
			tab `colvar'
				local num_cols = r(r)
			* Test if the var is cat or cts - more than 6 levels -> cts
			tab `demo_name'
			if r(r) >6.5 local cts=1
				else local cts=0
			if `cts'==0 { // Categorical data
				count if missing(`demo_name')
				local mv = r(N)
				if `mv'!=0 local missingtext_`demo_name' " (`mv' missing values)"
				file write `fhandle' "`label_name' `missingtext_`demo_name''" _n
					levelsof `demo_name', local(categories)
					foreach i of local categories {
						capture confirm numeric variable `demo_name' // This bit distinguishes between coded&labelled vars, and string vars.
								if !_rc local value_label: label (`demo_name') `i'
									else {
										local value_label = "`i'"
										local i = `""`i'""' // This is necessary so we can test for equality with i, as a string.
										}
						file write `fhandle' "`value_label'"
						levelsof `colvar', local(arms)
						foreach j of local arms {
							count if `colvar'==`j' & !missing(`demo_name')
							local denominator = r(N)
							count if `demo_name'==`i' & `colvar'==`j'
							local a = r(N)
							local ap = trim("`: display %10.1f (100 * `a' / `denominator')'")
							if `a'==0 file write `fhandle' _tab "0"
								else file write `fhandle' _tab "`a' (`ap'%)"
						}
						* Now do the total column, if required
						if "`total'" != "" {
							count if !missing(`demo_name') & !missing(`colvar')
							local denominator = r(N)
							count if `demo_name'==`i' & !missing(`colvar')
							local a = r(N)
							local ap = trim("`: display %10.1f (100 * `a' / `denominator')'")
							if `a'==0 file write `fhandle' _tab "0"
								else file write `fhandle' _tab "`a' (`ap'%)"
						} // end if TOTAL column
						file write `fhandle' _n
					}
				} // End of categorical IF statement
				else { // Continuous
					count if missing(`demo_name')
					local mv = r(N)
					if `mv'!=0 local missingtext_`demo_name' "(`mv' missing values)"
					* Median etc
						file write `fhandle' "`label_name'; Median (IQR) `missingtext_`demo_name''"
						tabstat `demo_name', by(`colvar') save s(p25 p50 p75)
							forvalues i=1/`num_cols' {
								mat A = r(Stat`i')
								local m_low = trim("`: display %10.2f (A[1,1])'")
								local m_med = trim("`: display %10.1f (A[2,1])'")
								local m_high = trim("`: display %10.1f (A[3,1])'")
								file write `fhandle' _tab "`m_med' (`m_low' - `m_high')"
							} // end of i loop over columns
						* Total, if reqd
						if "`total'" != "" {
							tabstat `demo_name', by(`colvar') save s(p25 p50 p75)
								mat C = r(StatTotal)
								local t_low = trim("`: display %10.2f (C[1,1])'")
								local t_med = trim("`: display %10.1f (C[2,1])'")
								local t_high = trim("`: display %10.1f (C[3,1])'")
								file write `fhandle' _tab "`t_med' (`t_low' - `t_high')"
						} // End of TOTAL if statement
						*
						file write `fhandle' _n
						* Mean
						file write `fhandle' "`label_name'; Mean (SD) `missingtext_`demo_name''"
						tabstat `demo_name', by(`colvar') save s(mean sd)
							forvalues i=1/`num_cols' {
								mat A = r(Stat`i')
								local m_mean = trim("`: display %10.2f (A[1,1])'")
								local m_sd = trim("`: display %10.1f (A[2,1])'")
								file write `fhandle' _tab "`m_mean' (`m_sd')"
							} // End of i loop over columns
						* Total, if reqd
						if "`total'" != "" {
							tabstat `demo_name', by(`colvar') save s(mean sd)
								mat C = r(StatTotal)
								local t_mean = trim("`: display %10.2f (C[1,1])'")
								local t_sd = trim("`: display %10.1f (C[2,1])'")
								file write `fhandle' _tab "`t_mean' (`t_sd')"
						} // End of TOTAL if statement

					file write `fhandle' _n
				} // End of continuous section
			} // end loop of variables
	restore
end

** END **
