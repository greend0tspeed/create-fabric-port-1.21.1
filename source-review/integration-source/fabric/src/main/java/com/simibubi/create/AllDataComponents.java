package com.simibubi.create;

import com.mojang.serialization.Codec;
import com.simibubi.create.content.logistics.box.PackageItem.PackageOrderData;
import com.simibubi.create.content.logistics.redstoneRequester.AutoRequestData;
import com.simibubi.create.content.logistics.stockTicker.PackageOrderWithCrafts;
import com.simibubi.create.content.logistics.tableCloth.ShoppingListItem.ShoppingList;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Registry;
import net.minecraft.core.component.DataComponentType;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.world.item.component.ItemContainerContents;

public class AllDataComponents {
	
	public static DataComponentType<CompoundTag> MINECART_CONTRAPTION = null;
	public static DataComponentType<CompoundTag> CLIPBOARD_EDITING = null;
	public static DataComponentType<CompoundTag> BLUEPRINT_DATA = null;
	public static DataComponentType<CompoundTag> FILTER_DATA = null;
	public static DataComponentType<CompoundTag> POLISHING = null;
	public static DataComponentType<CompoundTag> SYM_WAND = null;
	public static DataComponentType<CompoundTag> TOOLBOX = null;
	public static DataComponentType<CompoundTag> ZAPPER = null;
	public static DataComponentType<CompoundTag> BOTTLE_TYPE = null;
	public static DataComponentType<CompoundTag> SEQUENCED_ASSEMBLY = null;
	public static DataComponentType<CompoundTag> SCHEMATIC_DATA = null;
	public static DataComponentType<CompoundTag> SCHEDULE_DATA = null;
	public static DataComponentType<CompoundTag> TRACK_ITEM = null;
	public static DataComponentType<CompoundTag> TRACK_TARGETING = null;
	public static DataComponentType<BlockPos> DISPLAY_LINK_POS = null;
	public static DataComponentType<BlockPos> FIRST_PULLEY = null;
	public static DataComponentType<Integer> AIR_TANK = null;
	public static DataComponentType<Boolean> INFERRED_FROM_RECIPE = null;
	public static DataComponentType<Integer> COLLECTING_LIGHT = null;
	public static DataComponentType<String> PACKAGE_ADDRESS = null;
	public static DataComponentType<ItemContainerContents> PACKAGE_CONTENTS = null;
	public static DataComponentType<PackageOrderData> PACKAGE_ORDER_DATA = null;
	public static DataComponentType<PackageOrderWithCrafts> PACKAGE_ORDER_CONTEXT = null;
	public static DataComponentType<AutoRequestData> AUTO_REQUEST_DATA = null;
	public static DataComponentType<ShoppingList> SHOPPING_LIST = null;
	public static DataComponentType<String> SHOPPING_LIST_ADDRESS = null;
	
	public static void register() {
		MINECART_CONTRAPTION = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:minecart_contraption", 
				(new DataComponentType.Builder<CompoundTag>())
					.persistent(CompoundTag.CODEC)
					.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
					.cacheEncoding()
					.build());
		BLUEPRINT_DATA = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:blueprint_data", 
				(new DataComponentType.Builder<CompoundTag>())
					.persistent(CompoundTag.CODEC)
					.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
					.cacheEncoding()
					.build());
		FILTER_DATA = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:filter_data", 
				(new DataComponentType.Builder<CompoundTag>())
					.persistent(CompoundTag.CODEC)
					.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
					.cacheEncoding()
					.build());
		CLIPBOARD_EDITING = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:clipboard_editing", 
				(new DataComponentType.Builder<CompoundTag>())
					.persistent(CompoundTag.CODEC)
					.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
					.cacheEncoding()
					.build());
		POLISHING = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:polishing", 
				(new DataComponentType.Builder<CompoundTag>())
					.persistent(CompoundTag.CODEC)
					.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
					.cacheEncoding()
					.build());
		SYM_WAND = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:symmetry_wand", 
				(new DataComponentType.Builder<CompoundTag>())
					.persistent(CompoundTag.CODEC)
					.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
					.cacheEncoding()
					.build());
		TOOLBOX = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:toolbox", 
				(new DataComponentType.Builder<CompoundTag>())
					.persistent(CompoundTag.CODEC)
					.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
					.cacheEncoding()
					.build());
		ZAPPER = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:zapper", 
				(new DataComponentType.Builder<CompoundTag>())
					.persistent(CompoundTag.CODEC)
					.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
					.cacheEncoding()
					.build());
		BOTTLE_TYPE = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:bottle_type", 
				(new DataComponentType.Builder<CompoundTag>())
					.persistent(CompoundTag.CODEC)
					.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
					.cacheEncoding()
					.build());
		SEQUENCED_ASSEMBLY = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:sequenced_assembly", 
				(new DataComponentType.Builder<CompoundTag>())
				.persistent(CompoundTag.CODEC)
				.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
				.cacheEncoding()
				.build());
		SCHEMATIC_DATA = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:schematic_data", 
				(new DataComponentType.Builder<CompoundTag>())
				.persistent(CompoundTag.CODEC)
				.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
				.cacheEncoding()
				.build());
		SCHEDULE_DATA = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:schedule_data", 
				(new DataComponentType.Builder<CompoundTag>())
				.persistent(CompoundTag.CODEC)
				.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
				.cacheEncoding()
				.build());
		TRACK_ITEM = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:track_item", 
				(new DataComponentType.Builder<CompoundTag>())
				.persistent(CompoundTag.CODEC)
				.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
				.cacheEncoding()
				.build());
		TRACK_TARGETING = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:track_targeting", 
				(new DataComponentType.Builder<CompoundTag>())
				.persistent(CompoundTag.CODEC)
				.networkSynchronized(ByteBufCodecs.COMPOUND_TAG)
				.cacheEncoding()
				.build());
		FIRST_PULLEY = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:first_pulley", 
				(new DataComponentType.Builder<BlockPos>())
					.persistent(BlockPos.CODEC)
					.networkSynchronized(BlockPos.STREAM_CODEC)
					.cacheEncoding()
					.build());
		DISPLAY_LINK_POS = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:display_link_pos", 
				(new DataComponentType.Builder<BlockPos>())
					.persistent(BlockPos.CODEC)
					.networkSynchronized(BlockPos.STREAM_CODEC)
					.cacheEncoding()
					.build());
		AIR_TANK = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:air_tank", 
				(new DataComponentType.Builder<Integer>())
					.persistent(Codec.INT)
					.networkSynchronized(ByteBufCodecs.INT)
					.cacheEncoding()
					.build());
		INFERRED_FROM_RECIPE = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:inferred_from_recipe", 
				(new DataComponentType.Builder<Boolean>())
					.persistent(Codec.BOOL)
					.networkSynchronized(ByteBufCodecs.BOOL)
					.cacheEncoding()
					.build());
		COLLECTING_LIGHT = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:collecting_light", 
				(new DataComponentType.Builder<Integer>())
					.persistent(Codec.INT)
					.networkSynchronized(ByteBufCodecs.INT)
					.cacheEncoding()
					.build());
		PACKAGE_ADDRESS = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:package_address",
			(new DataComponentType.Builder<String>()).persistent(Codec.STRING).networkSynchronized(ByteBufCodecs.STRING_UTF8).cacheEncoding().build());
		PACKAGE_CONTENTS = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:package_contents",
			(new DataComponentType.Builder<ItemContainerContents>()).persistent(ItemContainerContents.CODEC).networkSynchronized(ItemContainerContents.STREAM_CODEC).cacheEncoding().build());
		PACKAGE_ORDER_DATA = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:package_order_data",
			(new DataComponentType.Builder<PackageOrderData>()).persistent(PackageOrderData.CODEC).networkSynchronized(PackageOrderData.STREAM_CODEC).cacheEncoding().build());
		PACKAGE_ORDER_CONTEXT = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:package_order_context",
			(new DataComponentType.Builder<PackageOrderWithCrafts>()).persistent(PackageOrderWithCrafts.CODEC).networkSynchronized(PackageOrderWithCrafts.STREAM_CODEC).cacheEncoding().build());
		AUTO_REQUEST_DATA = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:auto_request_data",
			(new DataComponentType.Builder<AutoRequestData>()).persistent(AutoRequestData.CODEC).networkSynchronized(AutoRequestData.STREAM_CODEC).cacheEncoding().build());
		SHOPPING_LIST = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:shopping_list",
			(new DataComponentType.Builder<ShoppingList>()).persistent(ShoppingList.CODEC).networkSynchronized(ShoppingList.STREAM_CODEC).cacheEncoding().build());
		SHOPPING_LIST_ADDRESS = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:shopping_list_address",
			(new DataComponentType.Builder<String>()).persistent(Codec.STRING).networkSynchronized(ByteBufCodecs.STRING_UTF8).cacheEncoding().build());
	}
	
}
