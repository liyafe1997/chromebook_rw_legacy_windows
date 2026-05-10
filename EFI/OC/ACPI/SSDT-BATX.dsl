DefinitionBlock ("", "SSDT", 2, "RULL", "BATX", 0x0000000D)
{
    External (\_SB.PCI0.LPCB.EC0.BAT0, DeviceObj)

    External (\_SB.PCI0.LPCB.EC0.BTVO, FieldUnitObj)
    External (\_SB.PCI0.LPCB.EC0.BTPR, FieldUnitObj)
    External (\_SB.PCI0.LPCB.EC0.BTRA, FieldUnitObj)

    External (\_SB.PCI0.LPCB.EC0.BFDC, FieldUnitObj)
    External (\_SB.PCI0.LPCB.EC0.BFCG, FieldUnitObj)
    External (\_SB.PCI0.LPCB.EC0.BFCR, FieldUnitObj)

    External (\_SB.PCI0.LPCB.EC0.BTDA, FieldUnitObj)
    External (\_SB.PCI0.LPCB.EC0.BTDV, FieldUnitObj)
    External (\_SB.PCI0.LPCB.EC0.BTDF, FieldUnitObj)
    External (\_SB.PCI0.LPCB.EC0.BTCC, FieldUnitObj)

    Scope (\_SB.PCI0.LPCB.EC0.BAT0)
    {
        Method (TOMW, 2, NotSerialized)
        {
            Local7 = Multiply (Arg0, Arg1)
            Divide (Local7, 1000, Local6, Local5)
            Return (Local5)
        }

        Method (DVL0, 0, NotSerialized)
        {
            Return (\_SB.PCI0.LPCB.EC0.BTDV)
        }

        Method (DSN0, 0, NotSerialized)
        {
            Return (TOMW (\_SB.PCI0.LPCB.EC0.BTDA, DVL0 ()))
        }

        Method (FLC0, 0, NotSerialized)
        {
            Return (TOMW (\_SB.PCI0.LPCB.EC0.BTDF, DVL0 ()))
        }

        Method (CYC0, 0, NotSerialized)
        {
            Return (\_SB.PCI0.LPCB.EC0.BTCC)
        }

        Method (BSTS, 0, NotSerialized)
        {
            Local0 = Zero

            If (\_SB.PCI0.LPCB.EC0.BFDC)
            {
                Or (Local0, One, Local0)
            }

            If (\_SB.PCI0.LPCB.EC0.BFCG)
            {
                Or (Local0, 0x02, Local0)
            }

            If (\_SB.PCI0.LPCB.EC0.BFCR)
            {
                Or (Local0, 0x04, Local0)
            }

            Return (Local0)
        }

        Method (_BIF, 0, NotSerialized)
        {
            Local0 = DSN0 ()   // Design Capacity, mWh
            Local1 = FLC0 ()   // Last Full, mWh
            Local2 = DVL0 ()   // Design Voltage, mV

            Local3 = Package (0x0D)
            {
                Zero, Zero, Zero, One, Zero, Zero, Zero, One, One,
                "BAT0", "1000", "LION", "ChromeEC"
            }

            Store (Zero,   Index (Local3, 0x00)) // Power Unit = mW/mWh
            Store (Local0, Index (Local3, 0x01)) // Design Capacity
            Store (Local1, Index (Local3, 0x02)) // Last Full Charge Capacity
            Store (One,    Index (Local3, 0x03)) // Battery Technology
            Store (Local2, Index (Local3, 0x04)) // Design Voltage

            Divide (Local0, 10, Local7, Local6)
            Store (Local6, Index (Local3, 0x05)) // Warning = 10%

            Divide (Local0, 20, Local7, Local6)
            Store (Local6, Index (Local3, 0x06)) // Low = 5%

            Store (One, Index (Local3, 0x07))
            Store (One, Index (Local3, 0x08))

            Return (Local3)
        }

        Method (_BIX, 0, NotSerialized)
        {
            Local0 = DSN0 ()   // Design Capacity, mWh
            Local1 = FLC0 ()   // Last Full, mWh
            Local2 = DVL0 ()   // Design Voltage, mV
            Local3 = CYC0 ()   // Cycle Count

            Local4 = Package (0x14)
            {
                Zero, Zero, Zero, Zero, One, Zero, Zero, Zero,
                One, 0x00018000, 500, 10, 0xFFFFFFFF, 0xFFFFFFFF,
                One, One, "BAT0", "1000", "LION", "ChromeEC"
            }

            Store (Zero,   Index (Local4, 0x00)) // Revision
            Store (Zero,   Index (Local4, 0x01)) // Power Unit = mW/mWh
            Store (Local0, Index (Local4, 0x02)) // Design Capacity
            Store (Local1, Index (Local4, 0x03)) // Last Full Charge Capacity
            Store (One,    Index (Local4, 0x04)) // Battery Technology
            Store (Local2, Index (Local4, 0x05)) // Design Voltage

            Divide (Local0, 10, Local7, Local6)
            Store (Local6, Index (Local4, 0x06)) // Warning = 10%

            Divide (Local0, 20, Local7, Local6)
            Store (Local6, Index (Local4, 0x07)) // Low = 5%

            Store (Local3,      Index (Local4, 0x08)) // Cycle Count
            Store (0x00018000,  Index (Local4, 0x09))
            Store (500,         Index (Local4, 0x0A))
            Store (10,          Index (Local4, 0x0B))
            Store (0xFFFFFFFF,  Index (Local4, 0x0C))
            Store (0xFFFFFFFF,  Index (Local4, 0x0D))
            Store (One,         Index (Local4, 0x0E))
            Store (One,         Index (Local4, 0x0F))
            Store ("BAT0",         Index (Local4, 0x10))
            Store ("1000",            Index (Local4, 0x11))
            Store ("LION",            Index (Local4, 0x12))
            Store ("ChromeEC",  Index (Local4, 0x13))

            Return (Local4)
        }

        Method (_BST, 0, NotSerialized)
        {
            Local0 = BSTS ()                         // State
            Local1 = \_SB.PCI0.LPCB.EC0.BTPR         // Rate, mA
            Local2 = \_SB.PCI0.LPCB.EC0.BTRA         // Remaining, mAh
            Local3 = \_SB.PCI0.LPCB.EC0.BTVO         // Voltage, mV

            Local4 = TOMW (Local1, Local3) // Rate, mW
            Local5 = TOMW (Local2, Local3) // Remaining, mWh

            If (LEqual (Local0, Zero))
            {
                Local4 = Zero
            }

            Local6 = Package (0x04) { Zero, Zero, Zero, Zero }

            Store (Local0, Index (Local6, 0x00))
            Store (Local4, Index (Local6, 0x01))
            Store (Local5, Index (Local6, 0x02))
            Store (Local3, Index (Local6, 0x03))

            Return (Local6)
        }
    }
}