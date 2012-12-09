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
/** \protocol FLContainer_protocol
 * Basic previous/next item handling in a list from a child.
 *
 * This protocol is accessed by children view controllers who require
 * their parent view controller to change their item to the next in
 * the list. This allows the child controller to ignore any details
 * about the implementation of the parent's list and encourages
 * reuse of the current child view controller for the previous/text
 * item.
 */
@protocol FLContainer_protocol <NSObject>

@required

/// Returns YES if there is a previous item to the currently viewed item.
- (BOOL)has_previous;

/// Returns YES if there is a next item to the currently viewed item.
- (BOOL)has_next;

/** Requests the parent to change the currently viewed item.
 * A positive value indicates advancement forward in the list,
 * negative opposite. A zero value is ignored, though it should be a
 * programming error.
 */
- (void)switch_item:(int)direction;

/** Tells the parent to disconnect the child.
 * This method allows the child to request the parent to break the
 * link. This doesn't happen on the iPhone, but it happens on the
 * iPad where you can switch the detail view without the former parent
 * view getting the viewWillAppear message, where the parent/child
 * container relationship is usually reset. So this is more of an
 * iPad safeguard than a proper way of doing stuff? Who knows.
 */
- (void)disconnect_child:(id)child;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
