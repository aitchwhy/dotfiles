## Prompt:
which of hammerspoon configs is best for mac os vim programmer like me very keyboard driven?

## Response:
Based on the document and your needs as a keyboard-driven Vim programmer, these configurations stand out:

1.  Ki.spoon - Most comprehensive Vim-like environment:

*   Modal hotkeys similar to Vim
*   Pre-configured shortcuts for stock macOS apps
*   Customizable modes and actions

2.  VimMode.spoon - Direct Vim integration:

*   Adds Vim movements to any macOS input
*   Supports `jk` for normal mode
*   Implements comprehensive motions/operators

3.  spacehammer - Spacemacs-inspired:

*   Clean, modal interface
*   Familiar to Vim users who like Spacemacs
*   Efficient keyboard-driven workflow

Recommendation: Start with Ki.spoon since it offers the most complete Vim-like experience while maintaining flexibility for customization. Its modal system will feel natural coming from Vim, and you can gradually extend it as needed.

Installation: Visit [https://github.com/andweeb/ki](https://github.com/andweeb/ki) for setup instructions.

Want me to explain any specific features of these configurations?

## Prompt:
I love launcher prefix like lazy nvim telescope that is prefixed by sensible key mappings and is very easy to view and edit. I also use many mac apps so like apps like homerow for scrolling + clicking. And windows+tabs+apps mgmt along with workspaces mgmt is crucial.

## Response:
Based on your preferences for a Lazy.nvim/Telescope-like experience with comprehensive app/window management, let me recommend the most suitable configs:

1.  MenuHammer would be your best primary option because it:

*   Uses a Spacemacs-style prefix menu system (very similar to Telescope/Lazy.nvim)
*   Fully customizable menus defined in simple tables
*   Can chain commands like you would with Telescope
*   Easy to view and edit configurations

2.  Combine it with:

*   szymon\_k's configuration for:
    *   Smart app launching/cycling (like Telescope frecency)
    *   Advanced space management with visual indicators
    *   Window movement between workspaces

3.  For your app-heavy workflow, also consider adding:

*   gwww's `smartLaunch` module for cycling through app windows
*   pstadler's fast space switching
*   windvalley's auto input method switching between apps

Example setup approach:

```lua
-- Example prefix-based launcher (MenuHammer style)
local launcher = {
  prefix = {"cmd", "space"},  -- Similar to Telescope prefix
  entries = {
    f = {action = "findFiles", desc = "Find Files"},
    a = {action = "findApps", desc = "Find Applications"},
    w = {action = "windowManager", desc = "Manage Windows"},
    s = {action = "switchSpace", desc = "Switch Space"}
  }
}
```

Would you like me to:

1.  Show more specific configuration examples for any of these components?
2.  Explain how to integrate multiple configs while avoiding conflicts?

## Prompt:
are these modern configurations? I use nvim + x-cmd + zsh shell commands + very fuzzy style search and context driven workflows

## Response:
Looking at the timestamps and modern developer workflows, let me suggest more contemporary configurations:

1.  spacehammer ([https://github.com/agzam/spacehammer](https://github.com/agzam/spacehammer)) is the most modern and aligned with your workflow because it:

*   Actively maintained (recent commits)
*   Built for developers using terminal-centric workflows
*   Integrates well with Neovim context switching
*   Has fuzzy-finder style interactions

2.  STRML's configuration also pairs well because:

*   Built for terminal-first developers
*   Has Vim-style `hjkl` navigation
*   Integrates with modern app workflows

However, looking through these configs, I notice many are a few years old. For your modern workflow combining Neovim + x-cmd + zsh, you might want to consider:

1.  Building a custom config focused on:

```lua
-- Example modern approach
local wezterm = require('wezterm')  -- For terminal management
local fuzzy = require('telescope')   -- For fuzzy-style searching

-- Context-aware app switching
function smartContextSwitch()
  local currentApp = hs.application.frontmostApplication()
  if currentApp:name() == "Neovim" then
    -- Handle Neovim context
  elseif currentApp:name() == "WezTerm" then
    -- Handle terminal context
  end
end

-- Fuzzy command palette (similar to Telescope)
function cmdPalette()
  -- Implement fuzzy finder for commands
end
```

Would you like me to:

1.  Help you build a modern config from scratch aligned with your workflow?
2.  Show how to adapt spacehammer specifically for Neovim + terminal workflows?

The main challenge is that many Hammerspoon configs haven't kept pace with modern development workflows centered around Neovim, fuzzy-finding, and context-switching. A custom solution might serve you better.

## Prompt:
additionally I use a lot of Raycast + obsidian app + drafts + termius / working copy on iphone ipad

and starting to adopt more seriously Kanata/yabai/Nix

Here are my brew apps + pkgs listed

Copy

`tap "coder/coder" tap "homebrew/bundle" tap "homebrew/services" tap "koekeishiya/formulae" tap "olets/tap" tap "rfidresearchgroup/proxmark3" tap "stripe/stripe-cli" tap "temporalio/brew" tap "typesense/tap" tap "waydabber/betterdisplay" tap "xo/xo" brew "act" brew "shellcheck" brew "actionlint" brew "aider" brew "angle-grinder" brew "ast-grep" brew "atuin", restart_service: :changed brew "localstack" brew "awscli-local" brew "bat" brew "biome" brew "node" brew "bitwarden-cli" brew "broot" brew "cheat" brew "cloudflare-wrangler2" brew "curlie" brew "wget" brew "dasht" brew "datasette" brew "direnv" brew "dust" brew "esbuild" brew "eslint" brew "exiftool" brew "eza" brew "fastfetch" brew "fd" brew "ffmpeg" brew "fx" brew "gdrive" brew "gdrive-downloader" brew "gh" brew "ghi" brew "git" brew "git-delta" brew "glances" brew "glow" brew "gping" brew "grex" brew "gron" brew "helix" brew "hexyl" brew "htop" brew "http-prompt" brew "httrack" brew "hurl" brew "hyperfine" brew "imagemagick" brew "jd" brew "jq" brew "just" brew "k9s" brew "kanata" brew "lazygit" brew "lua-language-server" brew "luarocks" brew "mas" brew "mcfly" brew "miller" brew "minio" brew "nasm" brew "neovim" brew "netcat" brew "nextdns" brew "nmap" brew "nnn" brew "odin" brew "onefetch" brew "pandoc" brew "parallel" brew "pinentry-mac" brew "pkgconf" brew "poppler" brew "posting" brew "prettier" brew "procs" brew "prometheus" brew "pyenv" brew "rclone" brew "ripgrep" brew "rollup" brew "ruff" brew "rust" brew "rustscan" brew "scrapy" brew "sd" brew "sevenzip" brew "skaffold" brew "speedtest-cli" brew "speexdsp" brew "sq" brew "temporal" brew "tldr" brew "traefik" brew "tree" brew "trippy" brew "uv" brew "vite" brew "volta" brew "weasyprint" brew "xclip" brew "yazi" brew "yq" brew "zellij" brew "zoxide" brew "zsh-autopair" brew "zsh-autosuggestions" brew "zsh-completions" brew "zsh-history-substring-search" brew "zsh-syntax-highlighting" brew "coder/coder/coder" brew "koekeishiya/formulae/skhd" brew "olets/tap/zsh-abbr" brew "olets/tap/zsh-autosuggestions-abbreviations-strategy" brew "rfidresearchgroup/proxmark3/proxmark3" brew "stripe/stripe-cli/stripe" brew "temporalio/brew/tcld" cask "aide-app" cask "arc" cask "carbon-copy-cloner" cask "cursor" cask "dash" cask "font-symbols-only-nerd-font" cask "ghidra" cask "google-drive" cask "hopper-disassembler" cask "istat-menus" cask "virtualbuddy" mas "Amphetamine", id: 937984704 mas "Bear", id: 1091189122 mas "Bitwarden", id: 1352778147 mas "Canva", id: 897446215 mas "Charmstone", id: 1563735522 mas "Cleaner for Xcode", id: 1296084683 mas "CleanMyMac", id: 1339170533 mas "Day One", id: 1055511498 mas "Drafts", id: 1435957248 mas "Dropover", id: 1355679052 mas "Fantastical", id: 975937182 mas "Flow", id: 1423210932 mas "Focus", id: 777233759 mas "KakaoTalk", id: 869223134 mas "Keynote", id: 409183694 mas "Kindle", id: 302584613 mas "LanScan", id: 472226235 mas "lire", id: 1482527526 mas "Numbers", id: 409203825 mas "One Thing", id: 1604176982 mas "Pages", id: 409201541 mas "Pandan", id: 1569600264 mas "Pixea", id: 1507782672 mas "Todoist", id: 585829637 mas "Toggl Track", id: 1291898086 mas "Transcribe AI", id: 6479871768 mas "Tripsy", id: 1429967544 mas "Ulysses", id: 1225570693 com.apple.pkg.MAContent10_AssetPack_0575_DrummerManchesterGBLogic com.apple.pkg.MAContent10_AssetPack_0830_EXS_ElectronicDrumkitsDarkSecrets com.apple.pkg.MAContent10_AssetPack_0858_EXS_ElectronicDrumkitsTakeADaytripSoHo com.apple.pkg.MAContent10_AssetPack_0286_AlchemyVocalsSoloVocalsSustainMisc com.apple.pkg.MAContent10_AssetPack_0827_AppleLoopsUltimate808s com.apple.pkg.MAContent10_AssetPack_0066_AlchemySoundscapesCustomNSingle com.apple.pkg.CLTools_SDK_macOS13 com.apple.pkg.MAContent10_AssetPack_0859_EXS_ElectronicDrumkitsTakeADaytripWashington com.apple.pkg.MAContent10_AssetPack_0676_EXS_ElectronicDrumkitsElectronicPop com.apple.pkg.MAContent10_AssetPack_0251_AlchemySynthsDigitalRackChord com.apple.pkg.MAContent10_AssetPack_0019_AlchemyLoopsMelodic com.apple.pkg.MAContent10_AssetPack_0836_AppleLoopsBacklightBounce com.apple.pkg.MAContent10_AssetPack_0831_EXS_ElectronicDrumkitsFluidShadow com.apple.pkg.MAContent10_AssetPack_0647_AppleLoopsDrummerPercussion com.apple.pkg.MAContent10_AssetPack_0569_DrummerFourOnTheFloorGBLogic com.apple.pkg.MAContent10_AssetPack_0226_AlchemySynthsAnalogResonant com.apple.pkg.MAContent10_AssetPack_0138_AlchemyGuitarsPluckedForgottenHarp com.apple.pkg.MAContent10_AssetPack_0726_AppleLoopsToyBox com.apple.pkg.MAContent10_AssetPack_0571_DrummerHeavyGBLogic com.apple.pkg.MAContent10_AssetPack_0130_AlchemyGuitarsAcousticTrad com.apple.pkg.CLTools_SDK_macOS12 com.apple.pkg.MAContent10_AssetPack_0668_AppleLoopsReggaetonPop com.apple.pkg.MAContent10_AssetPack_0330_AppleLoopsJamPackWorld com.apple.pkg.MAContent10_AssetPack_0022_AlchemyDrumsMisc com.apple.pkg.MAContent10_AssetPack_0503_EXS_ChoirChamberClassical com.apple.pkg.MAContent10_AssetPack_0494_EXS_OrchPercGlockenspiel com.apple.pkg.MAContent10_AssetPack_0573_DrummerLiverpoolGBLogic com.apple.pkg.MAContent10_AssetPack_0730_EXS_ElectronicDrumkitsVintageCR8000 com.apple.pkg.XProtectPlistConfigData_10_15.16U4352 com.apple.pkg.MAContent10_AssetPack_0757_EXS_ElectronicDrumkitsBlowingSpeakers com.apple.pkg.MAContent10_AssetPack_0833_EXS_ElectronicDrumkitsRadiantFlow com.apple.pkg.MAContent10_AssetPack_0864_EXS_ElectronicDrumkitsWatchTheSoundInTheKitches com.apple.pkg.MAContent10_AssetPack_0637_AppleLoopsDrummerKyle com.apple.pkg.MAContent10_AssetPack_0849_EXS_ElectronicDrumkitsOakFelderTwoTonPop com.apple.pkg.MAContent10_AssetPack_0593_DrummerSoCalGBLogic com.apple.pkg.MAContent10_AssetPack_0008_AlchemyKeysAcoustic com.apple.pkg.MAContent10_AssetPack_0899_EXS_ElectronicDrumkitsAnalogBliss com.apple.pkg.CLTools_Executables com.apple.pkg.MAContent10_AssetPack_0810_EXS_ElectronicDrumkitsAbstractThought com.apple.pkg.MAContent10_AssetPack_0085_AlchemySoundscapesOrangeDirt com.apple.pkg.MAContent10_AssetPack_0909_AppleLoopsModularRhythms com.apple.files.data-template com.apple.pkg.MAContent10_AssetPack_0696_DrummerSpeakeasyGBLogic com.apple.pkg.MAContent10_AssetPack_0654_AlchemySettingsGozaderaLatina com.apple.pkg.CLTools_SDK_macOS_LMOS com.apple.pkg.MAContent10_AssetPack_0857_EXS_ElectronicDrumkitsTakeADaytripHillsborough com.apple.pkg.MAContent10_AssetPack_0361_EXS_BassElectricMuted com.apple.pkg.MAContent10_AssetPack_0616_LogicAlchemyEssentials com.apple.pkg.MAContent10_AssetPack_0921_AppleLoops8BitLegends com.apple.pkg.MAContent10_AssetPack_0824_EXS_ElectronicDrumkitsShadowZone com.apple.pkg.MAContent10_AssetPack_0808_EXS_808HiHats com.apple.pkg.MAContent10_AssetPack_0141_AlchemyGuitarsPluckedDulimar com.apple.pkg.MAContent10_AssetPack_0931_AppleLoopsVoxMelodic com.apple.pkg.GatekeeperCompatibilityData.16U1906 com.apple.pkg.MAContent10_AssetPack_0876_EXS_ElectronicDrumkitsTomMischUptownFlow com.apple.pkg.MAContent10_AssetPack_0761_EXS_ElectronicDrumkitsRedLine com.apple.pkg.XProtectPlistConfigData_10_15.16U4347 com.apple.pkg.XProtectPlistConfigData_10_15.16U4353 com.apple.pkg.MAContent10_AssetPack_0199_AlchemySynthsAnalog1974 com.apple.pkg.MAContent10_AssetPack_0887_AlchemySettingsAlphaWaves com.apple.pkg.MAContent10_AssetPack_0028_AlchemyDrumsUnusualIceFX com.apple.pkg.MAContent10_AssetPack_0317_AppleLoopsModernRnB1 com.apple.pkg.MAContent10_AssetPack_0823_EXS_ElectronicDrumkitsSecretSauce com.apple.pkg.MAContent10_AssetPack_0537_DrummerShaker com.apple.pkg.MAContent10_AssetPack_0707_AlchemyKeysCustom com.apple.pkg.MAContent10_AssetPack_0837_AlchemyBacklightBounce com.apple.pkg.MAContent10_AssetPack_0715_EXS_ElectronicDrumkitsRetroBox com.apple.pkg.MAContent10_AssetPack_0198_AlchemySynthsSingleNCustom com.apple.pkg.MAContent10_AssetPack_0567_DrummerEastBayGBLogic com.apple.pkg.MAContent10_AssetPack_0482_EXS_OrchWoodwindAltoSax com.apple.pkg.CLTools_SDK_macOS14 com.apple.pkg.MAContent10_AssetPack_0924_EXS_ElectronicDrumkitsLowTechFunk com.apple.pkg.CLTools_SDK_macOS_NMOS com.apple.pkg.MAContent10_AssetPack_0679_EXS_ElectronicDrumkitsHacienda com.apple.pkg.MAContent10_AssetPack_0845_EXS_ElectronicDrumkitsBoysNoizeNaturalStructures com.apple.pkg.MAContent10_AssetPack_0005_AlchemyStrings com.apple.pkg.MAContent10_AssetPack_0234_AlchemySynthsAnalogMisc com.apple.pkg.MAContent10_AssetPack_0885_AppleLoopsAlphaWaves com.apple.pkg.MAContent10_AssetPack_0305_AlchemyVocalsVocalPhrasesAnastacia com.apple.pkg.MAContent10_AssetPack_0604_EXS_WorldPipa com.apple.pkg.MAContent10_AssetPack_0010_AlchemyMalletsMisc com.apple.pkg.MAContent10_AssetPack_0236_AlchemySynthsDigitalPad com.apple.pkg.MAContent10_AssetPack_0897_EXS_ElectronicDrumkitsAnalogArchitecture com.apple.pkg.LogicProTrial com.apple.pkg.MAContent10_AssetPack_0674_EXS_ElectronicDrumkitsDeepEnd com.apple.pkg.MAContent10_AssetPack_0878_EXS_KeyboardsTrakgirl com.apple.pkg.MAContent10_AssetPack_0913_EXS_ElectronicDrumkitsClicksAndSticks com.apple.pkg.MAContent10_AssetPack_0377_EXS_Mellotron com.apple.pkg.MAContent10_AssetPack_0844_EXS_ElectronicDrumkitsBoysNoizeControlVoltage com.apple.pkg.MAContent10_AssetPack_0553_AppleLoopsChillwave2 com.apple.pkg.MAContent10_AssetPack_0628_AppleLoopsDrummerAidan com.apple.pkg.MAContent10_AssetPack_0714_EXS_ElectronicDrumkitsLiveFeel com.apple.pkg.MAContent10_AssetPack_0585_DrummerRootsGBLogic com.apple.pkg.CLTools_SDK_macOS110 com.apple.pkg.MAContent10_AssetPack_0334_IRsLargeSpacesHalls com.apple.pkg.MAContent10_AssetPack_0907_EXS_ElectronicDrumkitsPlonkyModular com.apple.pkg.MAContent10_AssetPack_0834_EXS_ElectronicDrumkitsSuperSolid com.apple.pkg.MAContent10_AssetPack_0048_AlchemyPadsDigitalHolyGhost com.apple.pkg.MAContent10_AssetPack_0338_IRsLargeSpacesOutdoor com.apple.pkg.MAContent10_AssetPack_0735_EXS_ElectronicDrumkitsVintageTR909 com.apple.pkg.MAContent10_AssetPack_0923_EXS_ElectronicDrumkitsConsoleOperator com.apple.pkg.MAContent10_AssetPack_0853_EXS_ElectronicDrumkitsSoulectionSoulFire com.apple.pkg.MAContent10_AssetPack_0510_EXS_Strings com.apple.pkg.MAContent10_AssetPack_0257_AlchemySynthsDigitalMisc com.apple.pkg.MAContent10_AssetPack_0728_EXS_ElectronicDrumkitsVintageLinnDrum com.apple.pkg.MAContent10_AssetPack_0868_EXS_KeyboardsWatchTheSound com.apple.pkg.MAContent10_AssetPack_0908_EXS_ElectronicDrumkitsWestCoastModular com.apple.pkg.MAContent10_AssetPack_0563_DrummerBrooklynGBLogic com.apple.pkg.MAContent10_AssetPack_0869_EXS_KeyboardsTakeADaytrip com.apple.pkg.MAContent10_AssetPack_0838_AppleLoopsBoyzNoize com.apple.pkg.MAContent10_AssetPack_0850_EXS_ElectronicDrumkitsSoulectionAmpedUp com.apple.pkg.MAContent10_AssetPack_0539_DrummerTambourine com.apple.pkg.MAContent10_AssetPack_0814_EXS_ElectronicDrumkitsDoubleVision com.apple.pkg.MAContent10_AssetPack_0760_EXS_ElectronicDrumkitsJaggedEdges com.apple.pkg.MAContent10_AssetPack_0847_EXS_ElectronicDrumkitsOakFelderHitSynth com.apple.pkg.MAContent10_AssetPack_0443_EXS_WorldAfricanMarimba com.apple.pkg.MAContent10_AssetPack_0091_AlchemyBassMini3VCOSaws com.apple.pkg.MAContent10_AssetPack_0704_AppleLoopsHipHop com.apple.pkg.MAContent10_AssetPack_0602_EXS_WorldChineseKit com.apple.pkg.MAContent10_AssetPack_0712_EXS_ElectronicDrumkitsHybridKnock com.apple.pkg.MAContent10_AssetPack_0200_AlchemySynthsAnalogAnalog com.apple.pkg.MAContent10_AssetPack_0683_EXS_ElectronicDrumkitsModern808 com.apple.pkg.MAContent10_AssetPack_0812_EXS_ElectronicDrumkitsDeepCrunch com.apple.pkg.MAContent10_AssetPack_0906_EXS_ElectronicDrumkitsModularSpace com.apple.pkg.MAContent10_AssetPack_0323_AppleLoopsVintageBreaks com.apple.pkg.MAContent10_AssetPack_0487_EXS_OrchWoodwindFluteSolo com.apple.pkg.MAContent10_AssetPack_0557_IRsSharedAUX com.apple.pkg.MAContent10_AssetPack_0589_DrummerSlowJamGBLogic com.apple.pkg.MAContent10_AssetPack_0720_EXS_ToyPiano com.apple.pkg.MAContent10_AssetPack_0658_AlchemySoundEffectsToyPercussion com.apple.pkg.MAContent10_AssetPack_0862_EXS_ElectronicDrumkitsWatchTheSoundCR78MadeIconic com.apple.pkg.MAContent10_AssetPack_0034_AlchemyDrumsUnusualCupOfTea com.apple.pkg.MAContent10_AssetPack_0818_EXS_ElectronicDrumkitsMetallicEdges com.apple.pkg.MAContent10_AssetPack_0822_EXS_ElectronicDrumkitsPlatinumDreams com.apple.pkg.MAContent10_AssetPack_0645_AppleLoopsDrummerZak com.apple.pkg.MAContent10_AssetPack_0484_EXS_OrchWoodwindClarinetSolo com.apple.pkg.MAContent10_AssetPack_0855_EXS_ElectronicDrumkitsTakeADaytripBrooklynBorough com.apple.pkg.MAContent10_AssetPack_0326_AppleLoopsJamPack1 com.apple.pkg.MAContent10_AssetPack_0566_DrummerDetroitGarageLogic com.apple.pkg.MAContent10_AssetPack_0329_AppleLoopsJamPackOrchestra com.apple.pkg.MAContent10_AssetPack_0839_AppleLoopsMarkLettieri com.apple.pkg.MAContent10_AssetPack_0129_AlchemyGuitarsAcousticAcoustic com.apple.pkg.MAContent10_AssetPack_0920_AlchemySettings8BitLegends com.apple.pkg.MAContent10_AssetPack_0905_EXS_ElectronicDrumkitsModularMayhem com.apple.pkg.MAContent10_AssetPack_0880_EXS_ElectronicDrumkitsTrakgirlHardKnocking com.apple.pkg.MAContent10_AssetPack_0634_AppleLoopsDrummerGraham com.apple.pkg.MAContent10_AssetPack_0863_EXS_ElectronicDrumkitsWatchTheSoundHollywoodFoley com.apple.pkg.MAContent10_AssetPack_0910_PlugInSettingsGBLogic com.apple.pkg.MRTConfigData_10_15.16U4211 com.apple.pkg.MAContent10_AssetPack_0751_EXS_ElectronicDrumkitsSyntheticBassHouse com.apple.pkg.MAContent10_AssetPack_0861_EXS_ElectronicDrumkitsTomMischLoFiFunk com.apple.pkg.MAContent10_AssetPack_0815_EXS_ElectronicDrumkitsFutureFlex com.apple.pkg.MAContent10_AssetPack_0708_AlchemyOrgansCustom com.apple.pkg.MAContent10_AssetPack_0310_UB_DrumMachineDesignerGB com.apple.pkg.MAContent10_AssetPack_0273_AlchemyVocalsFXNNoisesMisc com.apple.pkg.MAContent10_AssetPack_0316_AppleLoopsDubstep1 com.apple.pkg.MAContent10_AssetPack_0803_EXS_KeyboardCollection com.apple.pkg.MAContent10_AssetPack_0745_AlchemyBassHouse com.apple.pkg.MAContent10_AssetPack_0491_EXS_OrchBrass com.apple.pkg.MAContent10_AssetPack_0865_EXS_ElectronicDrumkitsWatchTheSoundLinnDrumTunedDown com.apple.pkg.MAContent10_AssetPack_0879_EXS_ElectronicDrumkitsTrakgirlGrimeyFunk com.apple.pkg.MAContent10_AssetPack_0809_EXS_ElectronicDrumkitsAbsoluteZero com.apple.pkg.MAContent10_AssetPack_0555_AppleLoopsGarageBand2 com.apple.pkg.MAContent10_AssetPack_0373_EXS_GuitarsAcousticClassical com.apple.pkg.MAContent10_AssetPack_0898_EXS_ElectronicDrumkitsAnalogBlaze com.apple.pkg.MAContent10_AssetPack_0659_AlchemySynthCustom com.apple.pkg.MAContent10_AssetPack_0919_AlchemySamples8BitLegends com.apple.pkg.MAContent10_AssetPack_0564_DrummerBrooklynLogic com.apple.pkg.MAContent10_AssetPack_0900_EXS_ElectronicDrumkitsAnalogDream com.apple.pkg.MAContent10_AssetPack_0560_LTPBasicPiano1 com.apple.pkg.MAContent10_AssetPack_0721_EXS_XyloKeyboard com.apple.pkg.MAContent10_AssetPack_0657_AlchemyPadsCustom com.apple.pkg.MAContent10_AssetPack_0841_AppleLoopsTomMisch com.apple.pkg.MAContent10_AssetPack_0605_EXS_ClassicalGrand com.apple.pkg.MAContent10_AssetPack_0710_AlchemyRhythmicCustomSynthCustom com.apple.pkg.MAContent10_AssetPack_0315_AppleLoopsElectroHouse1 com.apple.pkg.MAContent10_AssetPack_0319_AppleLoopsDeepHouse com.apple.pkg.MAContent10_AssetPack_0152_AlchemyGuitarsElectric12StringPluck com.apple.pkg.MAContent10_AssetPack_0322_AppleLoopsDiscoFunk1 com.apple.pkg.MAContent10_AssetPack_0597_LTPChordTrainer com.apple.pkg.MAContent10_AssetPack_0685_EXS_ElectronicDrumkitsPlatinum com.apple.pkg.MAContent10_AssetPack_0807_EXS_ElectronicDrumkitsAboveAndBeyond com.apple.pkg.MAContent10_AssetPack_0577_DrummerMotownRevisitedGBLogic com.apple.pkg.MAContent10_AssetPack_0873_IRsProducerPacks01 com.apple.pkg.MAContent10_AssetPack_0883_AppleLoopsOakFelder com.apple.pkg.MAContent10_AssetPack_0492_EXS_OrchKit com.apple.pkg.MAContent10_AssetPack_0773_AlchemySamplesPrismatica com.apple.pkg.MAContent10_AssetPack_0753_ElectronicDrumkitsPrismatica com.apple.pkg.MAContent10_AssetPack_0801_AppleLoopsPrismaticaB com.apple.pkg.MAContent10_AssetPack_0770_AppleLoopsVisionAndVerse com.apple.pkg.MAContent10_AssetPack_0587_DrummerScientificMethodGBLogic com.apple.pkg.MAContent10_AssetPack_0758_EXS_ElectronicDrumkitsHardBounce com.apple.pkg.MAContent10_AssetPack_0912_EXS_ElectronicDrumkitsChoppedUpKit com.apple.pkg.MAContent10_AssetPack_0341_IRsWarpedMovingSpaces com.apple.pkg.MAContent10_AssetPack_0742_AppleLoopsTransitionEffects com.apple.pkg.MAContent10_AssetPack_0364_EXS_BassElectricStinger com.apple.pkg.MAContent10_AssetPack_0819_EXS_ElectronicDrumkitsModernKnock com.apple.pkg.MAContent10_AssetPack_0544_EXS_GuitarsGB com.apple.pkg.MAContent10_AssetPack_0776_EXS_ElectronicDrumkitsVisionAndVerse com.apple.pkg.MAContent10_AssetPack_0846_EXS_ElectronicDrumkitsOakFelderAcousticBump com.apple.pkg.MAContent10_AssetPack_0552_AppleLoopsModernRnB2 com.apple.pkg.MAContent10_AssetPack_0705_AlchemySettingsFlexAndFlow com.apple.pkg.MAContent10_AssetPack_0540_PlugInSettingsGB com.apple.pkg.MAContent10_AssetPack_0911_AppleLoopsBeatTape com.apple.pkg.MAContent10_AssetPack_0638_AppleLoopsDrummerLevi com.apple.pkg.MAContent10_AssetPack_0375_EXS_GuitarsVintageStrat com.apple.pkg.MAContent10_AssetPack_0501_EXS_OrchOrgan com.apple.pkg.MAContent10_AssetPack_0835_EXS_ElectronicDrumkitsWarmEmbers com.apple.pkg.MAContent10_AssetPack_0852_EXS_ElectronicDrumkitsSoulectionCreamSoda com.apple.pkg.MAContent10_AssetPack_0732_EXS_ElectronicDrumkitsVintageTR707 com.apple.pkg.MAContent10_AssetPack_0737_EXS_ElectronicDrumkitsVintageSDSV com.apple.pkg.MAContent10_AssetPack_0633_AppleLoopsDrummerGavin com.apple.pkg.InstallAssistant.macOSSequoia com.apple.pkg.MAContent10_AssetPack_0643_AppleLoopsDrummerParker com.apple.pkg.MAContent10_AssetPack_0925_EXS_ElectronicDrumkitsModernChiptune com.apple.pkg.MAContent10_AssetPack_0860_EXS_ElectronicDrumkitsTomMischAgogoFunk com.apple.pkg.MAContent10_AssetPack_0238_AlchemySynthsDigitalPluck com.apple.pkg.MAContent10_AssetPack_0804_IRsLargeSpacesSprings com.apple.pkg.MAContent10_AssetPack_0332_IRsMediumSpaces com.apple.pkg.MAContent10_AssetPack_0656_AlchemyMallets com.apple.pkg.MAContent10_AssetPack_0630_AppleLoopsDrummerBenny com.apple.pkg.MAContent10_AssetPack_0724_EXS_ElectronicDrumkitsKnickKnack com.apple.pkg.MAContent10_AssetPack_0904_EXS_ElectronicDrumkitsModularDrop com.apple.pkg.MAContent10_AssetPack_0826_EXS_ElectronicDrumkitsTitansOfBass com.apple.pkg.MAContent10_AssetPack_0636_AppleLoopsDrummerJesse com.apple.pkg.MAContent10_AssetPack_0615_GBLogicAlchemyEssentials com.apple.pkg.MAContent10_AssetPack_0328_AppleLoopsJamRhythmSection com.apple.pkg.MAContent10_AssetPack_0551_AppleLoopsDubstep2 com.apple.pkg.MAContent10_AssetPack_0691_IRsInstrumentProfiles com.apple.pkg.MAContent10_AssetPack_0509_EXS_StringsEnsemble com.apple.pkg.MAContent10_AssetPack_0903_EXS_ElectronicDrumkitsMicroModular com.apple.pkg.MAContent10_AssetPack_0629_AppleLoopsDrummerAnders com.apple.pkg.MAContent10_AssetPack_0729_EXS_ElectronicDrumkitsVintageCR78 com.apple.pkg.MAContent10_AssetPack_0131_AlchemyGuitarsAcousticMisc com.apple.pkg.MAContent10_AssetPack_0324_AppleLoopsBluesGarage com.apple.pkg.MAContent10_AssetPack_0314_AppleLoopsHipHop1 com.apple.pkg.MAContent10_AssetPack_0927_EXS_ElectronicDrumkitsPoppingBits com.apple.pkg.MAContent10_AssetPack_0635_AppleLoopsDrummerIan com.apple.pkg.MAContent10_AssetPack_0333_IRsLargeSpacesRooms com.apple.pkg.RosettaUpdateAuto com.apple.pkg.MAContent10_AssetPack_0756_AppleLoopsSkylineHeat com.apple.pkg.MAContent10_AssetPack_0641_AppleLoopsDrummerMax com.apple.pkg.MAContent10_AssetPack_0680_EXS_ElectronicDrumkitsInfinity com.apple.pkg.MAContent10_AssetPack_0867_EXS_ElectronicDrumkitsWatchTheSoundPawnShop808 com.apple.pkg.MAContent10_AssetPack_0670_EXS_ElectronicDrumkitsAdvancedMachines com.apple.pkg.MAContent10_AssetPack_0105_AlchemyBassAnalogAnalogMisc com.apple.pkg.MAContent10_AssetPack_0886_AlchemySamplesAlphaWaves com.apple.pkg.MAContent10_AssetPack_0296_AlchemySoundEffectsSynths com.apple.pkg.MAContent10_AssetPack_0662_AppleLoopsDrummerAustin com.apple.pkg.MAContent10_AssetPack_0922_EXS_ElectronicDrumkitsBattleBlocks com.apple.pkg.MAContent10_AssetPack_0483_EXS_OrchWoodwindBasson com.apple.pkg.MAContent10_AssetPack_0325_AppleLoopsGarageBand1 com.apple.pkg.MAContent10_AssetPack_0376_EXS_GuitarsWarmElectric com.apple.pkg.MAContent10_AssetPack_0825_EXS_ElectronicDrumkitsSuperNatural com.apple.pkg.MAContent10_AssetPack_0697_DrummerSpeakeasyLogic com.apple.pkg.MAContent10_AssetPack_0917_EXS_ElectronicDrumkitsStudioCuts com.apple.pkg.MAContent10_AssetPack_0681_EXS_ElectronicDrumkitsLaserBattle com.apple.pkg.MAContent10_AssetPack_0723_EXS_ToyMelodica com.apple.pkg.MAContent10_AssetPack_0337_IRsLargeSpacesIndoor com.apple.pkg.MAContent10_AssetPack_0579_DrummerNeoSoulGBLogic com.apple.pkg.MAContent10_AssetPack_0740_AppleLoopsHipHop3 com.apple.pkg.MAContent10_AssetPack_0339_IRsLargeSpacesWarped com.apple.pkg.MAContent10_AssetPack_0371_EXS_GuitarsAcoustic com.apple.pkg.MAContent10_AssetPack_0901_EXS_ElectronicDrumkitsAnalogHaze com.apple.pkg.MAContent10_AssetPack_0355_EXS_PianoGrand com.apple.pkg.MAContent10_AssetPack_0312_UB_UltrabeatKitsGBLogic com.apple.pkg.MAContent10_AssetPack_0762_EXS_ElectronicDrumkitsTightTrap com.apple.pkg.MAContent10_AssetPack_0561_DrummerBluebirdGBLogic com.apple.pkg.MAContent10_AssetPack_0646_AppleLoopsDrummerElectronic com.apple.pkg.MAContent10_AssetPack_0037_AlchemyPadsCustomNSingle com.apple.pkg.MAContent10_AssetPack_0875_ProducerPackSettingsOakFelder com.apple.pkg.MAContent10_AssetPack_0550_AppleLoopsElectroHouse2 com.apple.pkg.MAContent10_AssetPack_0749_EXS_ElectronicDrumkitsHeavyBassHouse com.apple.pkg.MAContent10_AssetPack_0205_AlchemySynthsAnalogDream com.apple.pkg.MAContent10_AssetPack_0598_LTPBasicGuitar1 com.apple.pkg.MAContent10_AssetPack_0843_EXS_ElectronicDrumkitsBoysNoizeBigBang com.apple.pkg.MAContent10_AssetPack_0733_EXS_ElectronicDrumkitsVintageTR727 com.apple.pkg.MAContent10_AssetPack_0682_EXS_ElectronicDrumkitsMinimalist com.apple.pkg.MAContent10_AssetPack_0007_AlchemyKeysElectric com.apple.pkg.MAContent10_AssetPack_0652_AlchemySettingsEdgesAndAngles com.apple.pkg.MAContent10_AssetPack_0688_EXS_WorldTaikoDrums com.apple.pkg.MAContent10_AssetPack_0866_EXS_ElectronicDrumkitsWatchTheSoundMixedBoomBap com.apple.pkg.MAContent10_AssetPack_0747_EXS_ElectronicDrumkitsDeepBassHouse com.apple.pkg.MAContent10_AssetPack_0345_IRsWarpedAnalogCircuits com.apple.pkg.MAContent10_AssetPack_0902_EXS_ElectronicDrumkitsAnalogTraces com.apple.pkg.MAContent10_AssetPack_0744_AppleLoopsChromiumFray com.apple.pkg.MAContent10_AssetPack_0811_EXS_ElectronicDrumkitsDarkArts com.apple.pkg.MAContent10_AssetPack_0884_EXS_KeyboardsSoulection com.apple.pkg.MAContent10_AssetPack_0854_EXS_ElectronicDrumkitsTakeADaytripAlphabetCity com.apple.pkg.MAContent10_AssetPack_0926_EXS_ElectronicDrumkitsOldSchool8Bit com.apple.pkg.MAContent10_AssetPack_0851_EXS_ElectronicDrumkitsSoulectionBigBump com.apple.pkg.MAContent10_AssetPack_0568_DrummerEastBayLogic com.apple.pkg.MAContent10_AssetPack_0583_DrummerRetroRockGBLogic com.apple.pkg.MAContent10_AssetPack_0661_DrummerBlueRidgeLogic com.apple.pkg.MAContent10_AssetPack_0667_AppleLoopsFutureBass com.apple.pkg.MAContent10_AssetPack_0820_EXS_ElectronicDrumkitsModernThrowback com.apple.pkg.MAContent10_AssetPack_0718_EXS_MusicBox com.apple.pkg.MAContent10_AssetPack_0354_EXS_PianoSteinway com.apple.pkg.MAContent10_AssetPack_0639_AppleLoopsDrummerLogan com.apple.pkg.MAContent10_AssetPack_0881_EXS_ElectronicDrumkitsTrakgirlLofiFeels com.apple.pkg.MAContent10_AssetPack_0370_EXS_MalletsVibraphone com.apple.pkg.MAContent10_AssetPack_0653_AlchemyBassCustom com.apple.pkg.MAContent10_AssetPack_0671_EXS_ElectronicDrumkitsArcadeFrenzy com.apple.pkg.MAContent10_AssetPack_0832_EXS_ElectronicDrumkitsPureHouse com.apple.pkg.MAContent10_AssetPack_0840_AppleLoopsTakeADaytrip com.apple.pkg.MAContent10_AssetPack_0321_AppleLoopsIndieDisco com.apple.pkg.MAContent10_AssetPack_0632_AppleLoopsDrummerDarcy com.apple.pkg.MAContent10_AssetPack_0145_AlchemyGuitarsPluckedHarp com.apple.pkg.MAContent10_AssetPack_0877_EXS_ElectronicDrumkitsTrakgirlMysticGroove com.apple.pkg.MAContent10_AssetPack_0603_EXS_WorldErhu com.apple.pkg.MAContent10_AssetPack_0299_AlchemyMalletsMetal com.apple.pkg.MAContent10_AssetPack_0660_DrummerBlueRidgeGBLogic com.apple.pkg.MAContent10_AssetPack_0362_EXS_BassElectricPicked com.apple.pkg.MAContent10_AssetPack_0601_AppleLoopsChineseTraditional com.apple.pkg.MAContent10_AssetPack_0842_EXS_ElectronicDrumkitsBoysNoizeAnalogDrive com.apple.pkg.MAContent10_AssetPack_0489_EXS_OrchWoodwindOboeSolo com.apple.pkg.MAContent10_AssetPack_0821_EXS_ElectronicDrumkitsOverdriveBump com.apple.pkg.MAContent10_AssetPack_0686_EXS_WorldGuzheng com.apple.pkg.MAContent10_AssetPack_0663_AppleLoopsDrummerTyrell com.apple.pkg.MAContent10_AssetPack_0748_EXS_ElectronicDrumkitsHardBassHouse com.apple.pkg.XProtectPayloads_10_15.16U4351 com.apple.pkg.MAContent10_AssetPack_0538_DrummerSticks com.apple.pkg.MAContent10_AssetPack_0731_EXS_ElectronicDrumkitsVintageTR606 com.apple.pkg.MAContent10_AssetPack_0581_DrummerPortlandGBLogic com.apple.pkg.MAContent10_AssetPack_0358_EXS_BassElectricFingerStyle com.apple.pkg.MAContent10_AssetPack_0677_EXS_ElectronicDrumkitsFoundSound com.apple.pkg.MAContent10_AssetPack_0882_AppleLoopsSoulection com.apple.pkg.MobileDeviceDevelopment com.apple.pkg.MAContent10_AssetPack_0713_EXS_ElectronicDrumkitsInterchange com.apple.pkg.MAContent10_AssetPack_0672_EXS_ElectronicDrumkitsBumper com.apple.pkg.MAContent10_AssetPack_0548_EXS_iOSInstruments com.apple.pkg.CLTools_SwiftBackDeploy com.apple.pkg.MAContent10_AssetPack_0292_AlchemySoundEffectsInstruments com.apple.pkg.MAContent10_AssetPack_0289_AlchemySoundEffectsNatural com.apple.pkg.MAContent10_AssetPack_0675_EXS_ElectronicDrumkitsDembow com.apple.pkg.MAContent10_AssetPack_0914_EXS_ElectronicDrumkitsDustBowl com.apple.pkg.MAContent10_AssetPack_0545_EXS_DrumsGB com.apple.pkg.MAContent10_AssetPack_0092_AlchemyBassMini3VCOSquares com.apple.pkg.MAContent10_AssetPack_0344_IRsWarpedSpeakers com.apple.pkg.MAContent10_AssetPack_0813_EXS_ElectronicDrumkitsDoingScience com.apple.pkg.MAContent10_AssetPack_0027_AlchemyDrumsElectronicMisc com.apple.pkg.MAContent10_AssetPack_0736_EXS_ElectronicDrumkitsVintageDrumTraks com.apple.pkg.MAContent10_AssetPack_0722_EXS_ElectronicDrumkits70sRhythmBox com.apple.pkg.MAContent10_AssetPack_0259_AlchemyVocalsChoirFemale com.apple.pkg.MAContent10_AssetPack_0562_DrummerBluebirdLogic com.apple.pkg.MAContent10_AssetPack_0915_EXS_ElectronicDrumkitsPreciousGems com.apple.pkg.MAContent10_AssetPack_0774_AlchemySettingsPrismatica com.apple.pkg.MAContent10_AssetPack_0816_EXS_ElectronicDrumkitsHybridGrime com.apple.pkg.MAContent10_AssetPack_0870_EXS_KeyboardsTomMisch com.apple.pkg.MAContent10_AssetPack_0684_EXS_ElectronicDrumkitsModern909 com.apple.pkg.MAContent10_AssetPack_0711_EXS_ElectronicDrumkits808Flex com.apple.pkg.MAContent10_AssetPack_0500_EXS_OrchHarp com.apple.pkg.MAContent10_AssetPack_0759_EXS_ElectronicDrumkitsHardKnock com.apple.pkg.MAContent10_AssetPack_0554_AppleLoopsDiscoFunk2 com.apple.pkg.MAContent10_AssetPack_0717_EXS_ToyGlockenspiel com.apple.pkg.CLTools_macOS_SDK com.apple.pkg.MAContent10_AssetPack_0817_EXS_ElectronicDrumkitsLoFiHype com.apple.pkg.MAContent10_AssetPack_0754_EXS_ElectronicDrumkitsSolaris com.apple.pkg.MAContent10_AssetPack_0283_AlchemyVocalsSoloVocalsSustainAnastacia com.apple.pkg.MAContent10_AssetPack_0293_AlchemySoundEffectsTechnology com.apple.pkg.MAContent10_AssetPack_0706_AlchemyBassCustom com.apple.pkg.MAContent10_AssetPack_0928_EXS_ElectronicDrumkitsVintageArcade com.apple.pkg.XcodeSystemResources com.apple.pkg.MAContent10_AssetPack_0595_DrummerSunsetGBLogic com.apple.pkg.MAContent10_AssetPack_0746_EXS_ElectronicDrumkitsBrightBassHouse com.apple.pkg.MAContent10_AssetPack_0591_DrummerSmashGBLogic com.apple.pkg.MAContent10_AssetPack_0743_SoundEffectsCustom2 com.apple.pkg.MAContent10_AssetPack_0644_AppleLoopsDrummerRose com.apple.pkg.MAContent10_AssetPack_0829_EXS_ElectronicDrumkitsHTownFire com.apple.pkg.MAContent10_AssetPack_0009_AlchemyMalletsSynthetic com.apple.pkg.MAContent10_AssetPack_0752_EXS_ElectronicDrumkitsModernDisco com.apple.pkg.MAContent10_AssetPack_0318_AppleLoopsTechHouse com.apple.pkg.MAContent10_AssetPack_0642_AppleLoopsDrummerNikki com.apple.pkg.MAContent10_AssetPack_0570_DrummerFourOnTheFloorLogic com.apple.pkg.MAContent10_AssetPack_0549_AppleLoopsHipHop2 com.apple.pkg.MAContent10_AssetPack_0565_DrummerDetroitGarageGBLogic com.apple.pkg.MAContent10_AssetPack_0655_AlchemyKeysCustom com.apple.pkg.MAContent10_AssetPack_0856_EXS_ElectronicDrumkitsTakeADaytripBurlington com.apple.pkg.MAContent10_AssetPack_0872_AppleLoopsWatchTheSound com.apple.pkg.MAContent10_AssetPack_0327_AppleLoopsJamPackRemixTools com.apple.pkg.MAContent10_AssetPack_0536_DrummerClapsCowbell com.apple.pkg.MAContent10_AssetPack_0802_AppleLoopsKeyboardCollection com.apple.pkg.MAContent10_AssetPack_0640_AppleLoopsDrummerMason com.apple.pkg.MAContent10_AssetPack_0874_AlchemyProducerPacks01 com.apple.pkg.MAContent10_AssetPack_0547_EXS_StringsGB com.apple.pkg.MAContent10_AssetPack_0871_AppleLoopsTrakgirl com.apple.pkg.MAContent10_AssetPack_0828_AlchemySamplesUltimate808s com.apple.pkg.MAContent10_AssetPack_0673_EXS_ElectronicDrumkitsCompact com.apple.pkg.MAContent10_AssetPack_0716_EXS_MiniMarimba com.apple.pkg.MAContent10_AssetPack_0848_EXS_ElectronicDrumkitsOakFelderMixedUp com.apple.pkg.MAContent10_AssetPack_0295_AlchemySoundEffectsAmbienceNature com.apple.pkg.MAContent10_AssetPack_0687_EXS_WorldKoto com.apple.pkg.MAContent10_AssetPack_0734_EXS_ElectronicDrumkitsVintageTR808 com.apple.pkg.XProtectPlistConfigData_10_15.16U4349 com.apple.pkg.MAContent10_AssetPack_0631_AppleLoopsDrummerCurtis com.apple.pkg.MAContent10_AssetPack_0678_EXS_ElectronicDrumkitsFutureBreaks com.apple.pkg.MAContent10_AssetPack_0331_IRsSmallSpaces com.apple.pkg.MAContent10_AssetPack_0360_EXS_BassElectricLiverpool com.apple.pkg.MAContent10_AssetPack_0750_EXS_ElectronicDrumkitsNaturalBassHouse com.apple.pkg.MAContent10_AssetPack_0648_Percussionist com.apple.pkg.MAContent10_AssetPack_0357_EXS_BassAcousticUprightJazz com.apple.pkg.MAContent10_AssetPack_0719_EXS_ToyCelesta com.apple.pkg.MAContent10_AssetPack_0709_AlchemyPadsCustom com.apple.pkg.MAContent10_AssetPack_0916_EXS_ElectronicDrumkitsSpacedOut com.apple.pkg.MAContent10_AssetPack_0320_AppleLoopsChillwave1 com.apple.pkg.MAContent10_AssetPack_0335_IRsLargeSpacesPlates com.apple.pkg.XProtectPlistConfigData_10_15.16U4348 dev.alexhay.MenuBox com.renfei.SnippetsLab com.apple.pkg.Pages14 com.toggl.daneel com.wiheads.paste com.sindresorhus.Pandan com.yubico.ykman org.erb.nutshellblack com.malteundjan.focus-osx com.lowtechguys.rcmd com.p5sys.jump.mac.viewer com.agiletortoise.Drafts-OSX app.pastenow.PasteNow design.yugen.Flow net.temurin.21.jdk com.if.Amphetamine com.amazon.Lassen com.canva.canvaeditor com.apple.pkg.iMovie_AppStore org.wireshark.ChmodBPF.pkg com.ua.transcribe.ai maccatalyst.com.lireapp.macOS com.yubico.yubioath com.hegenberg.BetterSnapTool com.flexibits.fantastical2.mac dk.simonbs.DataJar com.ulyssesapp.mac pl.wojciechkulik.Snippety com.focusrite.FocusriteControl com.logi.installer.pluginservice.media.package com.janandre.HomeKitTimers com.flexibits.cardhop.mac net.shinyfrog.bear com.amazon.aiv.AIVApp com.iwaxx.LanScan com.apple.pkg.GarageBand_AppStore com.google.Keystone com.marcoarment.instapaperpro recipes.mela.appkit org.pqrs.Karabiner-Elements com.sindresorhus.One-Thing com.bitwarden.desktop com.adobe.acrobat.AcrobatDCUpd2400420272 maccatalyst.com.overdesigned.Cheatsheet net.whatsapp.WhatsApp imagetasks.Pixea org.wireshark.path_helper.pkg com.tailscale.ipn.macsys com.journeytech.navigation com.termius.mac org.pqrs.Karabiner-DriverKit-VirtualHIDDevice com.apple.pkg.LogicPro_AppStore me.damir.dropover-mac com.bloombuilt.dayone-mac com.apple.pkg.Xcode com.alexhay.Console com.apple.pkg.Keynote14 app.tripsy.ios com.kakao.KakaoTalkMac cc.anybox.Anybox us.zoom.pkg.videomeeting ai.perplexity.mac io.tailscale.ipn.macos com.hyperdev.joinzoom.macos com.thomasricouard.IceCubesApp com.redhat.podman com.okatbest.boop io.hyperapp.XcodeCleaner com.mr-brightside.ParcelOSX com.todoist.mac.Todoist io.osquery.agent com.brettterpstra.marked2 com.apple.pkg.Numbers14 com.apple.pkg.ConfigurationUtility com.andydev.alpenglow com.logi.installer.pluginservice.package org.p0deje.Maccy com.knollsoft.Charmstone com.macpaw.CleanMyMac-mas com.henrikruscon.Klack tv.parsec.www com.apple.pkg.WWDC_Catalyst com.branchseer.rapidmg md.obsidian.Obsidian-Web-Clipper`

## Response:
Based on your extensive toolset and workflow preferences, let me suggest a modern Hammerspoon configuration approach that integrates well with your existing tools:

1.  Primary Configuration Strategy:

*   Use spacehammer as base but modernize it with:
    *   Raycast-like fuzzy finding
    *   Integration with Obsidian/Drafts for quick capture
    *   Context-aware window management that works with yabai
    *   Terminal-centric workflow support

Here's a suggested modern configuration approach:

```lua
-- Example modern Hammerspoon configuration structure
local wm = require('window-management')
local fuzzy = require('fuzzy')
local apps = require('apps')
local keys = require('keys')

-- Context-aware modal system (similar to your Neovim setup)
local function setupModes()
  local modes = {
    normal = {}, -- Default mode
    window = {}, -- Window management mode
    app = {},    -- App switching/launching mode
    nav = {},    -- Navigation mode
    capture = {} -- Quick capture to Obsidian/Drafts
  }
end

-- Fuzzy finder integration (Telescope-like)
local function setupFuzzy()
  -- Integrate with zoxide for smart directory jumping
  -- Add Raycast-like app switching
end

-- Terminal integration
local function setupTerminal()
  -- Integrate with zellij/wezterm
  -- Handle terminal-specific window rules
end
```

Would you like me to:

1.  Show how to integrate this with yabai for better window management?
2.  Create a Raycast-like fuzzy finder for your specific apps?
3.  Set up context-aware keybindings that adapt based on current app (Neovim/terminal/Obsidian)?

The key is building a configuration that complements your existing tools rather than replacing them, while maintaining the speed and flexibility you're used to from your terminal-centric workflow.

## Prompt:
modern CLi or easy online tool to clone entire website domain recursively?

## Response:
Based on your command-line expertise and tools list, here are the most modern and effective options:

1.  wget (already in your brew list):

```bash
wget --mirror --convert-links --adjust-extension --page-requisites --no-parent https://example.com
```

2.  httrack (already in your brew list):

```bash
httrack "https://example.com" -O "./website-clone" "+*.example.com/*" -v
```

However, for a more modern approach, I'd recommend:

3.  ArchiveBox

```bash
# Install
brew install archivebox

# Archive
archivebox add https://example.com
```

Key benefits:

*   Modern CLI interface
*   Better JavaScript handling
*   Multiple archive formats
*   API access
*   Built-in index/search

4.  For API-first sites, you might want to try:

```bash
# Using curl with rate limiting and retry
curl -H "Accept: application/json" \
     --retry 3 \
     --retry-delay 1 \
     -o "page-#1.json" \
     "https://api.example.com/pages/{1..100}"
```

5.  For dynamic sites specifically:

```javascript
# Using Browser-based Crawling
playwright-cli pdf https://example.com example.pdf
```

Recommendation: Start with wget since it's already installed and handles most cases well. If you need better JavaScript support or hit issues with dynamic content, move to ArchiveBox.

Want me to explain the specific flags for any of these tools?

