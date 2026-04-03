import pandas as pd
import numpy as np
# Fichier CSV original
input_csv = "salesorderheader_2012_2017.csv"
# Fichier CSV nettoyé pour dbt
output_csv = "salesorderheader_2012_2017_clean.csv"

# Colonnes à convertir en date
date_columns = ['modifieddate', 'orderdate', 'duedate', 'shipdate']

# Colonnes integer selon schema.yml
integer_cols = [
    'salesorderid', 'shipmethodid', 'billtoaddressid', 'shiptoaddressid', 
    'territoryid', 'status', 'creditcardid', 'currencyrateid', 'revisionnumber', 
    'customerid', 'salespersonid'
]
# Lire le CSV original
df = pd.read_csv(input_csv)

# 1️⃣ Convertir les dates en format YYYY-MM-DD
# for col in date_columns:
#     if col in df.columns:
#         df[col] = pd.to_datetime(df[col], dayfirst=True, errors='coerce').dt.date
# Convertir toutes les colonnes timestamp en format ISO
for col in date_columns:
    if col in df.columns:
        df[col] = pd.to_datetime(df[col], dayfirst=True, errors='coerce').dt.strftime('%Y-%m-%d %H:%M:%S')


# 2️⃣ Forcer creditcardid en int
# 2️⃣ Forcer toutes les colonnes integer
for col in integer_cols:
    if col in df.columns:
        df[col] = df[col].fillna(0).astype(int)
        
##Pour  salesorderheader
df = pd.read_csv("salesorderheader_2012_2017.csv")

# convertir en datetime
df['orderdate'] = pd.to_datetime(df['orderdate'], errors='coerce')
df['duedate'] = pd.to_datetime(df['duedate'], errors='coerce')

# générer des délais réalistes (1 à 10 jours)
random_delay = np.random.randint(1, 10, size=len(df))

# corriger uniquement les valeurs manquantes
df['orderdate'] = np.where(
    df['orderdate'].isna(),
    df['duedate'] - pd.to_timedelta(random_delay, unit='D'),
    df['orderdate']
)

# sécurité : OrderDate <= DueDate
df['orderdate'] = np.where(
    df['orderdate'] > df['duedate'],
    df['duedate'] - pd.to_timedelta(1, unit='D'),
    df['orderdate']
)

df.to_csv("salesorderheader_fixed.csv", index=False)
# 3️⃣ Réécrire le CSV propre
# df.to_csv(output_csv, index=False, encoding='utf-8')
