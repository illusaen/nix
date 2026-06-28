pref("browser.contentblocking.category", "strict");
pref("browser.download.start_downloads_in_tmp_dir", true);
pref("browser.uitour.enabled", false);
pref("privacy.globalprivacycontrol.enabled", true);

/** OCSP & CERTS / HPKP ***/
pref("security.OCSP.enabled", 0);
pref("privacy.antitracking.isolateContentScriptResources", true);
pref("security.csp.reporting.enabled", false);

/** SSL / TLS ***/
pref("security.ssl.treat_unsafe_negotiation_as_broken", true);
pref("browser.xul.error_pages.expert_bad_cert", true);
pref("security.tls.enable_0rtt_data", false);

/** DISK AVOIDANCE ***/
pref("browser.cache.disk.enable", false);
pref("browser.privatebrowsing.forceMediaMemoryCache", true);
pref("media.memory_cache_max_size", 65536);
pref("browser.sessionstore.interval", 60000);

/** SHUTDOWN & SANITIZING ***/
pref("privacy.history.custom", true);
pref("browser.privatebrowsing.resetPBM.enabled", true);

/** SPECULATIVE LOADING ***/
pref("network.http.speculative-parallel-limit", 0);
pref("network.dns.disablePrefetch", true);
pref("network.dns.disablePrefetchFromHTTPS", true);
pref("browser.urlbar.speculativeConnect.enabled", false);
pref("browser.places.speculativeConnect.enabled", false);
pref("network.prefetch-next", false);

/** SEARCH / URL BAR ***/
pref("browser.urlbar.trimHttps", true);
pref("browser.urlbar.untrimOnUserInteraction.featureGate", true);
pref("browser.search.separatePrivateDefault.ui.enabled", true);
pref("browser.search.suggest.enabled", false);
pref("browser.urlbar.quicksuggest.enabled", false);
pref("browser.urlbar.groupLabels.enabled", false);
pref("browser.formfill.enable", false);
pref("network.IDN_show_punycode", true);

/** HTTPS-ONLY MODE ***/
pref("dom.security.https_only_mode", true);
pref("dom.security.https_only_mode_error_page_user_suggestions", true);

/** PASSWORDS ***/
pref("signon.formlessCapture.enabled", false);
pref("signon.privateBrowsingCapture.enabled", false);
pref("network.auth.subresource-http-auth-allow", 1);
pref("editor.truncate_user_pastes", false);

/** EXTENSIONS ***/
pref("extensions.enabledScopes", 5);

/** HEADERS / REFERERS ***/
pref("network.http.referer.XOriginTrimmingPolicy", 2);

/** CONTAINERS ***/
pref("privacy.userContext.ui.enabled", true);

/** VARIOUS ***/
pref("pdfjs.enableScripting", false);

/** SAFE BROWSING ***/
pref("browser.safebrowsing.downloads.remote.enabled", false);

/** MOZILLA ***/
pref("permissions.default.desktop-notification", 2);
pref("permissions.default.geo", 2);
pref("geo.provider.network.url", "https://beacondb.net/v1/geolocate");
pref("browser.search.update", false);
pref("permissions.manager.defaultsUrl", "");
pref("extensions.getAddons.cache.enabled", false);

/** TELEMETRY ***/
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("datareporting.healthreport.uploadEnabled", false);
pref("toolkit.telemetry.unified", false);
pref("toolkit.telemetry.enabled", false);
pref("toolkit.telemetry.server", "data:,");
pref("toolkit.telemetry.archive.enabled", false);
pref("toolkit.telemetry.newProfilePing.enabled", false);
pref("toolkit.telemetry.shutdownPingSender.enabled", false);
pref("toolkit.telemetry.updatePing.enabled", false);
pref("toolkit.telemetry.bhrPing.enabled", false);
pref("toolkit.telemetry.firstShutdownPing.enabled", false);
pref("toolkit.telemetry.coverage.opt-out", true);
pref("toolkit.coverage.opt-out", true);
pref("toolkit.coverage.endpoint.base", "");
pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
pref("browser.newtabpage.activity-stream.telemetry", false);
pref("datareporting.usage.uploadEnabled", false);

/** EXPERIMENTS ***/
pref("app.shield.optoutstudies.enabled", false);
pref("app.normandy.enabled", false);
pref("app.normandy.api_url", "");

/** CRASH REPORTS ***/
pref("breakpad.reportURL", "");
pref("browser.tabs.crashReporting.sendReport", false);

/****************************************************************************
 * SECTION: PESKYFOX                                                        *
 ****************************************************************************/
/** MOZILLA UI ***/
pref("extensions.getAddons.showPane", false);
pref("extensions.htmlaboutaddons.recommendations.enabled", false);
pref("browser.discovery.enabled", false);
pref("browser.shell.checkDefaultBrowser", false);
pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
pref(
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features",
  false,
);
pref("browser.preferences.moreFromMozilla", false);
pref("browser.aboutConfig.showWarning", false);
pref("browser.startup.homepage_override.mstone", "ignore");
pref("browser.aboutwelcome.enabled", false);
pref("browser.profiles.enabled", true);

/** THEME ADJUSTMENTS ***/
pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
pref("browser.compactmode.show", true);
pref("browser.privateWindowSeparation.enabled", false); // WINDOWS

/** AI ***/
pref("browser.ai.control.default", "blocked");
pref("browser.ml.enable", false);
pref("browser.ml.chat.enabled", false);
pref("browser.ml.chat.menu", false);
pref("browser.tabs.groups.smart.enabled", false);
pref("browser.ml.linkPreview.enabled", false);

/** FULLSCREEN NOTICE ***/
pref("full-screen-api.transition-duration.enter", "0 0");
pref("full-screen-api.transition-duration.leave", "0 0");
pref("full-screen-api.warning.timeout", 0);

/** URL BAR ***/
pref("browser.urlbar.trending.featureGate", false);

/** NEW TAB PAGE ***/
pref("browser.newtabpage.activity-stream.default.sites", "");
pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
pref("browser.newtabpage.activity-stream.showSponsored", false);
pref("browser.newtabpage.activity-stream.showSponsoredCheckboxes", false);

/** DOWNLOADS ***/
pref("browser.download.manager.addToRecentDocs", false);

/** PDF ***/
pref("browser.download.open_pdf_attachments_inline", true);

/** TAB BEHAVIOR ***/
pref("browser.bookmarks.openInTabClosesMenu", false);
pref("browser.menu.showViewImageInfo", true);
pref("findbar.highlightAll", true);
pref("layout.word_select.eat_space_to_next_word", false);
