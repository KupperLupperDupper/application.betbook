/// Central route path definitions.
class Routes {
  const Routes._();

  static const onboarding = '/onboarding';
  static const home = '/';

  static const newSite = '/site/new';
  static String siteDetail(String id) => '/site/$id';
  static String editSite(String id) => '/site/$id/edit';
  static const siteDetailPath = '/site/:id';
  static const editSitePath = '/site/:id/edit';

  static const newTransaction = '/transaction/new';
  static String editTransaction(String id) => '/transaction/$id/edit';
  static const editTransactionPath = '/transaction/:id/edit';

  static const exchangeRates = '/settings/exchange-rates';
  static const responsibleGambling = '/settings/responsible-gambling';
  static const takeABreak = '/settings/take-a-break';
  static const tags = '/settings/tags';
}
