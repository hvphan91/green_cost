import pandas as pd
import os
import wbdata as wbd
from tqdm import tqdm

cls = lambda: os.system('cls')
os.chdir('...')

# get list of countries
clist = [c['id'] for c in pd.Series(wbd.get_countries()) if c['region']['id'] != 'NA']
ccode = pd.DataFrame(wbd.get_countries())[['id', 'iso2Code', 'name', 'incomeLevel']]

for i in range(len(ccode)):
    ccode.loc[i, 'incomeLevel'] = ccode.loc[i, 'incomeLevel']['value']


tco   = 'EN.GHG.CO2.MT.CE.AR5'  # Carbon dioxide (CO2) emissions (total) excluding LULUCF (Mt CO2e)
elcon = 'EG.USE.ELEC.KH.PC'    # Electric power consumption (kWh per capita) -- Electric power consumption per capita (kWh) is the production of power plants and combined heat and power plants less transmission, distribution, and transformation losses and own use by heat and power plants, divided by midyear population.
euse  = 'EG.USE.PCAP.KG.OE'      # Energy use refers to use of primary energy before transformation to other end-use fuels, which is equal to indigenous production plus imports and stock changes, minus exports and fuels supplied to ships and aircraft engaged in international transport.

gdpc = 'NY.GDP.PCAP.KD'         # GPD per capita, constant 2015 USD
pop  = 'SP.POP.TOTL'            # Population, total
urb  = 'SP.URB.TOTL.IN.ZS'      # Urban population, % of total population
trd  = 'NE.TRD.GNFS.ZS'         # Trade (export + import), % of GDP
ind  = 'NV.IND.TOTL.ZS'         # Industry value added, % of GDP

reout  = 'EG.ELC.RNEW.ZS'       # Renewable electricity output (% of total electricity output)
reprd  = 'EG.ELC.RNWX.ZS'       # Electricity production from renewable sources, excluding hydroelectric (% of total)
rehyd  = 'EG.ELC.HYRO.ZS'       # Electricity production from hydroelectric sources (% of total)
nuke   = 'EG.ELC.NUCL.ZS'       # Electricity production from nuclear sources (% of total)
recon  = 'EG.FEC.RNEW.ZS'       # Renewable energy consumption (% of total final energy consumption)

ffprd = 'EG.ELC.FOSL.ZS'        # Electricity production from oil, gas and coal sources (% of total)
ffcon = 'EG.USE.COMM.FO.ZS'     # Fossil fuel energy consumption (% of total)

enat  = 'EG.ELC.ACCS.ZS'        # Access to electricity (% of population)
enaru = 'EG.ELC.ACCS.RU.ZS'     # Access to electricity, rural (% of rural population)
enaub = 'EG.ELC.ACCS.UR.ZS'     # Access to electricity, urban (% of urban population)


indicators = {tco: 'tco',
              elcon: 'elcon',
              euse: 'euse',  
              gdpc: 'gdpc',
              pop: 'pop',
              urb: 'urb',
              trd: 'trd',
              ind: 'ind',
              reout: 'reout',
              reprd: 'reprd',
              rehyd: 'rehyd',
              nuke: 'nuke',
              recon: 'recon',              
              ffprd: 'ffprd',
              ffcon: 'ffcon',              
              enat: 'enat',
              enaru: 'enaru',
              enaub: 'enaub'}

# get data
data = []
for i in tqdm(indicators):
        df = wbd.get_dataframe({i: indicators[i]}, clist, date=('1990','2024'), freq='Y', source=None, parse_dates=False, keep_levels=False, skip_cache=True)
        data.append(df)

df = wbd.get_dataframe(indicators, clist, date=('1990','2024'), freq='Y', source=None, parse_dates=False, keep_levels=False, skip_cache=True)

df = df.reset_index()
df = df.rename(columns={'date':'year'})
df['year'] = df['year'].astype('int64')

df = df.merge(ccode, how='left', left_on='country', right_on='name')
df = df.drop(columns=['name'])

df.to_excel('wb_ren.xlsx', index=False)

ine = pd.read_excel('ine_data.xlsx')
for col in ['inc80', 'inc90', 'inc99', 'wea80', 'wea90', 'wea99']:
    ine[col] = ine[col] * 100
    
df = df.merge(ine, how='left', left_on=['iso2Code','year'], right_on=['code', 'year'])

df = df.drop(columns=['code', 'cc'])

df.to_excel('wb_data2.xlsx', index=False)



