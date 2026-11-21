package com.simibubi.create.content.logistics.packagePort;

import com.simibubi.create.AllPackets;

/**
 * Registers only the three package-port packets that are absent from the
 * 1.21.1 Fabric base. Keeping these outside AllPackets preserves every
 * existing packet id, including chain-conveyor construction packets.
 */
public final class FrogportPackets {
	private static final int PLACE_PACKAGE_PORT = 0x600;
	private static final int CONFIGURE_PACKAGE_PORT = 0x601;
	private static final int REQUEST_PACKAGE_PORT_TARGET = 0x602;

	private FrogportPackets() {}

	public static void register() {
		AllPackets.getChannel().registerC2SPacket(PackagePortPlacementPacket.class, PLACE_PACKAGE_PORT,
			PackagePortPlacementPacket::new);
		AllPackets.getChannel().registerC2SPacket(PackagePortConfigurationPacket.class, CONFIGURE_PACKAGE_PORT,
			PackagePortConfigurationPacket::new);
		AllPackets.getChannel().registerS2CPacket(PackagePortPlacementPacket.ClientBoundRequest.class,
			REQUEST_PACKAGE_PORT_TARGET, PackagePortPlacementPacket.ClientBoundRequest::new);
	}
}
