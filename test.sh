curl --silent  \
  -H "Referer: https://publicdashboards.dl.usda.gov/t/MRP_PUB/views/VS_Cattle_HPAIConfirmedDetections2024/HPAI2022ConfirmedDetections?%3Aembed=y&%3AisGuestRedirectFromVizportal=y" \
  -H "Accept: text/csv" \
  "https://publicdashboards.dl.usda.gov/t/MRP_PUB/views/VS_Cattle_HPAIConfirmedDetections2024/HPAI2022ConfirmedDetections/csv" > \
  data.csv
