DefinitionBlock ("", "SSDT", 2, "OC", "BRTFIX", 0x00000000)
{
    External (\_SB.PCI0.GFX0, DeviceObj)
    External (\_SB.PCI0.GFX0.LCD0, DeviceObj)

    Scope (\_SB.PCI0.GFX0)
    {
        Method (_DOD, 0, NotSerialized)
        {
            Return (Package (0x01)
            {
                0x80010400
            })
        }

        Method (_DOS, 1, NotSerialized)
        {
            // Windows/graphics driver may call this.
            // Do nothing for now.
        }
    }

    Scope (\_SB.PCI0.GFX0.LCD0)
    {
        Name (_ADR, 0x00000400)
        Name (BRTL, 0x64)

        Method (_BCL, 0, NotSerialized)
        {
            Return (Package ()
            {
                0x64,   // AC default
                0x32,   // Battery default

                0x00,
                0x0A,
                0x14,
                0x1E,
                0x28,
                0x32,
                0x3C,
                0x46,
                0x50,
                0x5A,
                0x64
            })
        }

        Method (_BCM, 1, NotSerialized)
        {
            BRTL = Arg0
        }

        Method (_BQC, 0, NotSerialized)
        {
            Return (BRTL)
        }
    }
}