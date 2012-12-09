//
// OpenIrekia v2.0 Cliente iOS
//
// Copyright 2009-2010 eFaber, S.L.
// Copyright 2009-2010 Ejie, S.A.
// Copyrigth 2009-2010 Dirección de Gobierno Abierto y Comunicación en Internet; 
//    Gobernu Irekirako eta Interneteko Komunikaziorako Zuzendaritza; Lehendakaritza.
//    Gobierno Vasco – Eusko Jaurlaritza 
// Licencia con arreglo a la EUPL, Versión 1.1 o –en cuanto sean aprobadas 
// por la Comisión Europea– versiones posteriores de la EUPL (la Licencia);
// Solo podrá usarse esta obra si se respeta la Licencia. Puede obtenerse una 
// copia de la Licencia en: http://ec.europa.eu/idabc/eupl 
// Salvo cuando lo exija la legislación aplicable o se acuerde por escrito, 
// el programa distribuido con arreglo a la Licencia se distribuye TAL CUAL,
// SIN GARANTÍAS NI CONDICIONES DE NINGÚN TIPO, ni expresas ni implícitas.
// Véase la Licencia en el idioma concreto que rige los permisos y limitaciones 
// que establece la Licencia
//
//  http://open.irekia.net, openirekia@efaber.net
#import "global/FLSharekit_configuration.h"

// If this file doesn't exist, copy it from FLSharekit_secrets.h.template.
#import "global/FLSharekit_secrets.h"

#import "ELHASO.h"

@implementation FLSharekit_configuration

- (NSString*)appName
{
	return @"Irekia";
}

- (NSString*)appURL
{
	return @"http://www.irekia.euskadi.net/es/pages/2775";
}

- (NSString*)facebookAppId
{
	return FL_FACEBOOK_APP_ID;
}

- (NSString*)twitterConsumerKey
{
	return FL_TWITTER_CONSUMER_KEY;
}

- (NSString*)twitterSecret
{
	return FL_TWITTER_SECRET;
}

- (NSString*)twitterCallbackUrl
{
	return FL_TWITTER_CALLBACK_URL;
}

- (NSString*)bitLyLogin
{
	return FL_BITLY_LOGIN;
}

- (NSString*)bitLyKey
{
	return FL_BITLY_KEY;
}

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
