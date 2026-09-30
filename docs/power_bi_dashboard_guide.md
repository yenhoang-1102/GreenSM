# Power BI Dashboard - Firebase Emulator

## 1. Tao cac truy van Power Query

Trong Power BI Desktop, chon **Transform data > New source > Blank query**. Tao lan luot 4 query ben duoi bang **Advanced Editor**.

### Query `AnalyticsSource`

Tat **Enable load** cho query nay sau khi tao xong.

```powerquery
let
    BaseUrl = "http://127.0.0.1:5001",
    Response = Json.Document(
        Web.Contents(
            BaseUrl,
            [
                RelativePath = "ride-booking-app-e2eb0/asia-southeast1/powerBiAnalytics",
                Query = [api_key = "my-local-power-bi-key"],
                Timeout = #duration(0, 0, 2, 0)
            ]
        )
    )
in
    Response
```

Khi Power BI hoi quyen truy cap, chon **Anonymous**, cap do `http://127.0.0.1:5001/`, roi bam **Connect**.

### Query `Bookings`

```powerquery
let
    Source = AnalyticsSource[bookings],
    Rows = Table.FromRecords(Source),
    Typed = Table.TransformColumnTypes(
        Rows,
        {
            {"bookingId", type text}, {"userId", type text},
            {"vehicleType", type text}, {"pickupAddress", type text},
            {"pickupLatitude", type number}, {"pickupLongitude", type number},
            {"destinationAddress", type text}, {"distanceKm", type number},
            {"estimatedDuration", Int64.Type}, {"estimatedPrice", Currency.Type},
            {"discountAmount", Currency.Type}, {"finalPrice", Currency.Type},
            {"voucherCode", type text}, {"status", type text},
            {"completionButton", type text}, {"lastButtonBeforeCompletion", type text},
            {"screenDurationSeconds", type number}, {"createdAt", type datetimezone}
        },
        "en-US"
    ),
    LocalTime = Table.TransformColumns(Typed, {{"createdAt", DateTimeZone.RemoveZone, type datetime}}),
    AddedDate = Table.AddColumn(LocalTime, "BookingDate", each Date.From([createdAt]), type date)
in
    AddedDate
```

### Query `FoodOrders`

```powerquery
let
    Source = AnalyticsSource[foodOrders],
    Rows = Table.FromRecords(Source),
    Typed = Table.TransformColumnTypes(
        Rows,
        {
            {"orderId", type text}, {"userId", type text},
            {"restaurant", type text}, {"deliveryAddress", type text},
            {"subtotal", Currency.Type}, {"shippingFee", Currency.Type},
            {"discountAmount", Currency.Type}, {"totalPrice", Currency.Type},
            {"voucherCode", type text}, {"status", type text},
            {"screenDurationSeconds", type number}, {"createdAt", type datetimezone}
        },
        "en-US"
    ),
    LocalTime = Table.TransformColumns(Typed, {{"createdAt", DateTimeZone.RemoveZone, type datetime}}),
    AddedDate = Table.AddColumn(LocalTime, "OrderDate", each Date.From([createdAt]), type date)
in
    AddedDate
```

### Query `EventLogs`

```powerquery
let
    Source = AnalyticsSource[eventLogs],
    Rows = Table.FromRecords(Source),
    Typed = Table.TransformColumnTypes(
        Rows,
        {
            {"eventId", type text}, {"eventName", type text}, {"userId", type text},
            {"bookingId", type text}, {"screen", type text}, {"device", type text},
            {"timeStep", Int64.Type}, {"createdAt", type datetimezone},
            {"locationAddress", type text}, {"locationLatitude", type number},
            {"locationLongitude", type number}, {"service", type text},
            {"vehicleName", type text}, {"vehiclePrice", Currency.Type},
            {"voucherCode", type text}, {"discountAmount", Currency.Type},
            {"finalPrice", Currency.Type}, {"restaurant", type text},
            {"itemName", type text}, {"category", type text},
            {"quantity", Int64.Type}, {"totalPrice", Currency.Type},
            {"rating", type number}, {"completionButton", type text},
            {"lastButtonBeforeCompletion", type text}, {"screenDurationSeconds", type number}
        },
        "en-US"
    ),
    LocalTime = Table.TransformColumns(Typed, {{"createdAt", DateTimeZone.RemoveZone, type datetime}}),
    AddedDate = Table.AddColumn(LocalTime, "EventDate", each Date.From([createdAt]), type date)
in
    AddedDate
```

Chon **Close & Apply**. Neu mot cot rong hoan toan van bao loi kieu du lieu, xoa cap ep kieu cua rieng cot do trong danh sach `Typed`.

## 2. Tao bang Calendar

Chon **Modeling > New table** va dan. Khong dan cong thuc nay vao **DAX Query View**; neu thay thong bao bat dau bang `Query (dong, cot)` thi ban dang o sai cua so.

```DAX
Calendar =
VAR MinBookingDate = MIN(Bookings[BookingDate])
VAR MinFoodDate = MIN(FoodOrders[OrderDate])
VAR MinEventDate = MIN(EventLogs[EventDate])
VAR MaxBookingDate = MAX(Bookings[BookingDate])
VAR MaxFoodDate = MAX(FoodOrders[OrderDate])
VAR MaxEventDate = MAX(EventLogs[EventDate])
VAR StartDate = MIN(MinBookingDate, MIN(MinFoodDate, MinEventDate))
VAR EndDate = MAX(MaxBookingDate, MAX(MaxFoodDate, MaxEventDate))
RETURN
ADDCOLUMNS(
    CALENDAR(StartDate, EndDate),
    "Year", YEAR([Date]),
    "MonthNo", MONTH([Date]),
    "Month", FORMAT([Date], "MM/yyyy"),
    "MonthSort", YEAR([Date]) * 100 + MONTH([Date]),
    "Weekday", FORMAT([Date], "ddd"),
    "Day", FORMAT([Date], "dd/MM/yyyy")
)
```

Chon `Calendar[Month]` > **Sort by column** > `MonthSort`. Sau do chon **Table tools > Mark as date table** va dung cot `Date`.

Trong **Model view**, tao 3 quan he one-to-many, cross-filter direction **Single**:

| Ben 1 | Ben nhieu |
|---|---|
| `Calendar[Date]` | `Bookings[BookingDate]` |
| `Calendar[Date]` | `FoodOrders[OrderDate]` |
| `Calendar[Date]` | `EventLogs[EventDate]` |

## 3. Measures DAX

Chon **Modeling > New measure** va tao tung measure:

```DAX
Total Bookings = COUNTROWS(Bookings)

Completed Bookings =
CALCULATE([Total Bookings], Bookings[status] = "completed")

Cancelled Bookings =
CALCULATE([Total Bookings], Bookings[status] = "cancelled")

Ride Completion Rate =
DIVIDE([Completed Bookings], [Total Bookings], 0)

Ride Revenue =
CALCULATE(SUM(Bookings[finalPrice]), Bookings[status] = "completed")

Average Ride Value =
DIVIDE([Ride Revenue], [Completed Bookings], 0)

Average Ride Distance = AVERAGE(Bookings[distanceKm])

Average Ride Screen Time = AVERAGE(Bookings[screenDurationSeconds])

Ride Voucher Usage =
CALCULATE(
    [Total Bookings],
    FILTER(Bookings, NOT ISBLANK(Bookings[voucherCode]))
)

Ride Voucher Rate = DIVIDE([Ride Voucher Usage], [Total Bookings], 0)

Total Food Orders = COUNTROWS(FoodOrders)

Completed Food Orders =
CALCULATE([Total Food Orders], FoodOrders[status] = "completed")

Cancelled Food Orders =
CALCULATE([Total Food Orders], FoodOrders[status] = "cancelled")

Food Completion Rate =
DIVIDE([Completed Food Orders], [Total Food Orders], 0)

Food Revenue =
CALCULATE(SUM(FoodOrders[totalPrice]), FoodOrders[status] = "completed")

Average Food Order Value =
DIVIDE([Food Revenue], [Completed Food Orders], 0)

Average Food Screen Time = AVERAGE(FoodOrders[screenDurationSeconds])

Food Voucher Usage =
CALCULATE(
    [Total Food Orders],
    FILTER(FoodOrders, NOT ISBLANK(FoodOrders[voucherCode]))
)

Total Revenue = [Ride Revenue] + [Food Revenue]

Total Transactions = [Total Bookings] + [Total Food Orders]

Total Events = COUNTROWS(EventLogs)

Unique Users =
COUNTROWS(
    DISTINCT(
        UNION(
            SELECTCOLUMNS(Bookings, "UserId", Bookings[userId]),
            SELECTCOLUMNS(FoodOrders, "UserId", FoodOrders[userId])
        )
    )
)

Average Event Screen Time = AVERAGE(EventLogs[screenDurationSeconds])

Previous Month Revenue =
CALCULATE([Total Revenue], DATEADD(Calendar[Date], -1, MONTH))

Revenue MoM % =
DIVIDE([Total Revenue] - [Previous Month Revenue], [Previous Month Revenue], 0)
```

Dinh dang `Ride Completion Rate`, `Food Completion Rate`, `Ride Voucher Rate`, `Revenue MoM %` la **Percentage**. Dinh dang cac measure doanh thu/gia tri la **Currency**, locale Vietnamese, khong co chu so thap phan.

## 4. Dashboard tong quan

Tao page `Tong quan`, kich thuoc **16:9**.

### Hang bo loc

| Visual | Field | Thiet lap |
|---|---|---|
| Slicer | `Calendar[Date]` | Style `Between` |
| Slicer | `Bookings[vehicleType]` | Style `Dropdown` |
| Slicer | `Bookings[status]` | Style `Dropdown` |

### KPI

Tao 6 **Card**:

| Tieu de | Field |
|---|---|
| Tong doanh thu | `[Total Revenue]` |
| Tong giao dich | `[Total Transactions]` |
| Chuyen xe hoan thanh | `[Completed Bookings]` |
| Don mon hoan thanh | `[Completed Food Orders]` |
| Ty le hoan thanh xe | `[Ride Completion Rate]` |
| Nguoi dung | `[Unique Users]` |

### Bieu do

1. **Line and clustered column chart - Doanh thu va giao dich**
   - X-axis: `Calendar[Date]`, hierarchy Month.
   - Column y-axis: `[Total Transactions]`.
   - Line y-axis: `[Total Revenue]`.
   - Sort tang dan theo `Calendar[Date]`.

2. **Donut chart - Co cau loai xe**
   - Legend: `Bookings[vehicleType]`.
   - Values: `[Total Bookings]`.
   - Detail labels: category va percent of total.

3. **Clustered bar chart - Doanh thu theo nha hang**
   - Y-axis: `FoodOrders[restaurant]`.
   - X-axis: `[Food Revenue]`.
   - Sort giam dan theo doanh thu.

4. **Stacked column chart - Trang thai giao dich**
   - X-axis: `Calendar[Month]`.
   - Legend: `Bookings[status]`.
   - Y-axis: `[Total Bookings]`.

5. **Table - Giao dich xe gan nhat**
   - `Bookings[createdAt]`, `vehicleType`, `pickupAddress`, `destinationAddress`, `status`, `finalPrice`.
   - Visual filter: Top N 10 theo `createdAt` moi nhat.
   - Conditional formatting `status`: completed mau xanh, cancelled mau do.

## 5. Dashboard hanh vi

Tao page `Hanh vi`.

1. **Card**: `[Total Events]`.
2. **Card**: `[Average Event Screen Time]`, suffix ` giay`.
3. **Clustered bar chart**:
   - Y-axis: `EventLogs[eventName]`.
   - X-axis: `[Total Events]`.
4. **Donut chart**:
   - Legend: `EventLogs[device]`.
   - Values: `[Total Events]`.
5. **Clustered column chart**:
   - X-axis: `EventLogs[screen]`.
   - Y-axis: `[Average Event Screen Time]`.
6. **Table**:
   - `createdAt`, `service`, `eventName`, `screen`, `completionButton`, `lastButtonBeforeCompletion`, `screenDurationSeconds`.
7. **Slicer**: `EventLogs[service]`, `EventLogs[device]`, `EventLogs[eventName]`.

## 6. Mau sac de xuat

- Nen trang: `#F7F9FA`
- Chu chinh: `#172B2D`
- Xanh thuong hieu: `#19BFC4`
- Xanh hoan thanh: `#168A62`
- Doanh thu/do an: `#F2A93B`
- Huy/loi: `#D9534F`
- Vien: `#DDE5E6`

Dung cung mot mau cho cung mot chi so tren moi page. Tat shadow nang, dat corner radius 6-8 px va giu khoang cach visual deu nhau.

## 7. Lam moi du lieu

Truoc khi bam **Refresh** trong Power BI, Firebase Emulator phai dang chay. Endpoint kiem tra:

```text
http://127.0.0.1:5001/ride-booking-app-e2eb0/asia-southeast1/powerBiAnalytics?api_key=my-local-power-bi-key
```

Neu gap loi credentials, vao **File > Options and settings > Data source settings**, xoa quyen cua `http://127.0.0.1:5001/`, ket noi lai bang **Anonymous**.
