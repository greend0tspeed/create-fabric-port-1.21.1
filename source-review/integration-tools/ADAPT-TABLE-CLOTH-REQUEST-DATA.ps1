$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot;$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Change([string]$path,[string]$from,[string]$to){$entry=$script:manifest.files|Where-Object path -EQ $path;if(!$entry){throw "Untracked source: $path"};$file="$root/source/fabric/src/main/java/com/simibubi/create/$path";$text=[IO.File]::ReadAllText($file);if(!$text.Contains($from)){if($text.Contains($to)){return};throw "Expected source missing: $path :: $from"};$entry.changes+=[pscustomobject]@{from=$from;to=$to};[IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))}
$be='content/logistics/tableCloth/TableClothBlockEntity.java'
Change $be 'import com.simibubi.create.AllItems;' "import com.simibubi.create.AllItems;`nimport com.simibubi.create.Create;"
Change $be 'import net.minecraft.nbt.CompoundTag;' "import net.minecraft.nbt.CompoundTag;`nimport net.minecraft.nbt.NbtOps;"
Change $be 'requestData.encodedRequest' 'requestData.encodedRequest()'
Change $be 'requestData.targetOffset' 'requestData.targetOffset()'
Change $be 'requestData.encodedTargetAdress' 'requestData.encodedTargetAddress()'
Change $be 'requestData.write(tag);' 'tag.put("RequestData", AutoRequestData.CODEC.encodeStart(Create.getRegistryAccess().createSerializationContext(NbtOps.INSTANCE), requestData).result().orElseThrow());'
Change $be 'requestData = AutoRequestData.read(tag);' 'requestData = AutoRequestData.CODEC.parse(registries.createSerializationContext(NbtOps.INSTANCE), tag.get("RequestData")).result().orElse(new AutoRequestData());'
$shopping='content/logistics/tableCloth/ShoppingListItem.java'
Change $shopping 'dcbe.requestData.encodedRequest.stacks()' 'dcbe.requestData.encodedRequest().stacks()'
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
