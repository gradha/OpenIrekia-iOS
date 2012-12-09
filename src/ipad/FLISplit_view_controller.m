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
#import "ipad/FLISplit_view_controller.h"

#import "controllers/FLTab_controller.h"
#import "global/FLi18n.h"
#import "global/settings.h"
#import "ipad/FLIBlank_view_controller.h"
#import "ipad/FLINavigation_controller.h"
#import "models/FLContent_item.h"

#import "ELHASO.h"


@interface FLISplit_view_controller ()

- (void)set_pop_button_title;
- (void)reset_tab_controller;
- (void)set_first_controller_button:(UIBarButtonItem*)button;
- (UIViewController*)first_controller;

@end


@implementation FLISplit_view_controller

@synthesize pop_controller = pop_controller_;
@synthesize pop_button = pop_button_;

- (id)init_with_master:(UIViewController*)controller
{
	LASSERT(controller, @"Bad pointer, bad programmer");
	if (self = [super init]) {
		blank_view_ = [FLIBlank_view_controller new];
		details_ = [[FLINavigation_controller alloc]
			initWithRootViewController:blank_view_];
		self.viewControllers = [NSArray arrayWithObjects:controller,
			details_, nil];
		[blank_view_ release];
		self.delegate = self;
	}
	return self;
}

- (void)dealloc
{
	[pop_controller_ release];
	[pop_button_ release];
	[details_ release];
	[super dealloc];
}

/** Allow all kinds of rotations. Weeeeee!
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:
	(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/** During initialisation the strings have not been yet loaded, and
 * the macro will return a nil string. Force resetting the button
 * text here again, when the strings are already loaded.
 *
 * Also does the same for the text label shown in the blank view
 * and queues a hack for the UITabBarController in landscape mode.
 */
- (void)recover_button_text
{
	[self set_pop_button_title];
	blank_view_.label.text = NON_NIL_STRING(_(STR_BROWSE_IPAD_SECTIONS));
	blank_view_ = nil;

	/* Queue hack for tab controller. */
	[self performSelector:@selector(reset_tab_controller)
		withObject:nil afterDelay:0.0];
}

/** Sets the title for the pop_button variable.
 * There are several ways to fill the title, so it is better to
 * have this function deal with it than duplicating the code. The
 * title is gotten from a protocol string. However, if the string is
 * empty, the title is then retrieved from the selected tab bar title.
 */
- (void)set_pop_button_title
{
	self.pop_button.title = NON_NIL_STRING(_(STR_IPAD_SECTION_BUTTON));
	/* Should we reset the title with the text of the section? */
	if (self.pop_button.title.length > 0)
		return;
	RASSERT(self.viewControllers.count > 0,
		@"I was expecting the tab controller", return);

	id controller = [self.viewControllers objectAtIndex:0];
	RASSERT([controller isKindOfClass:[FLTab_controller class]],
		@"First controller is not a tab controller?", return);
	FLTab_controller *tab_controller = (FLTab_controller*)controller;
	NSString *title = tab_controller.selectedViewController.title;
	if (title.length > 0) {
		self.pop_button.title = title;
		return;
	}

	/* If the title was empty or there was no selected tab view
	 * controller, get the title for the first tab if it exists.
	 */
	if (tab_controller.viewControllers.count < 1)
		return;
	title = [[tab_controller.viewControllers objectAtIndex:0] title];
	self.pop_button.title = title;
}

/** Ugly hack for landscape ipad launch orientation.
 * Having a tab controller in the master view seems to do evil with
 * the layout. Fortunately, if you switch the index of the tab
 * controller, the layouts reset themselves and everything looks ok.
 * So that's what this does. It changes quickly the index of the
 * selected tab to force a refresh, only if the first tab is selected.
 *
 * This has to be done once the launch method of the application
 * has finished, therefore you invoke this method after a delay. Also,
 * we don't care about landscape orientation, it works fine for
 * vertical too when the master view is hidden.
 */
- (void)reset_tab_controller
{
	/* Now, try to refresh the tab controller tab if it is zero
	 * and we are in landscape mode to avoid an ugly initialisation
	 * artifact.
	 */
	id controller = [self.viewControllers objectAtIndex:0];
	if (![controller isKindOfClass:[FLTab_controller class]])
		return;
	FLTab_controller *tab_controller = (FLTab_controller*)controller;
	/* Perform the forcefull switch only if we are showing the first tab. */
	if (tab_controller.selectedIndex > 0)
		return;

	DLOG(@"Uh oh, force tab switch to refresh detail view.");
	tab_controller.selectedIndex = 1;
	tab_controller.selectedIndex = 0;
}

/** Modifies the detail controller to be what is being passed.
 * You can pass nil, in which case a blank controller will be created.
 * This method replaces whatever hierarchy might have been in place.
 */
- (void)set_detail_controller:(UIViewController*)controller
{
	BOOL release = NO;
	if (!controller) {
		controller = [FLIBlank_view_controller new];
		release = YES;
	}

	[details_ set_root_view_controller:controller];
	[self set_first_controller_button:self.pop_button];
	[self set_pop_button_title];

	if (release)
		[controller release];
}

- (void)set_first_controller_button:(UIBarButtonItem*)button
{
	[self first_controller].navigationItem.leftBarButtonItem = button;
	[self.pop_controller dismissPopoverAnimated:YES];
}

/** Allows external code force a dismissal of the pop over.
 * This can be used for instance by news item trying to dismiss the
 * popover when the user presses the navigation arrows.
 */
- (void)dismiss_pop_over
{
	[self.pop_controller dismissPopoverAnimated:YES];
}

/** Returns the first view controller or nil if there wasn't any.
 */
- (UIViewController*)first_controller
{
	NSArray *controllers = details_.viewControllers;
	RASSERT(controllers.count > 0, @"Empty detail view?", return nil);
	return [controllers objectAtIndex:0];
}

/** Stores in the user defaults the currently viewed item with tab.
 * This method is called when the application is going to exit, so
 * it has to be quick. It simply stores the index of the currently
 * selected article. The article is saved only if it is possible
 * to identify which tab it belongs too.
 *
 * These saves are done for the purpose of recovering the previous
 * application state when the user returns.
 *
 * Note that this function doesn't explicitly sync the application
 * user defaults dictionary, you have to do it yourself.
 */
- (void)remember_current_tab_and_item
{
	if (self.viewControllers.count < 2 || details_.viewControllers.count < 1)
		return;

	id controller = [self.viewControllers objectAtIndex:0];
	if (![controller isKindOfClass:[FLTab_controller class]]) {
		LASSERT(0, @"First controller is not tab controller?");
		return;
	}

	FLTab_controller *tab_controller = (FLTab_controller*)controller;
	controller = [[details_ viewControllers] objectAtIndex:0];
	FLContent_item *item = ASK_GETTER(controller, item, nil);
	NSNumber *item_id = ASK_GETTER(controller, item_id, nil);
	int id_to_save = item ? item.id_ : (item_id ? [item_id intValue] : -1);
	int tab_to_save = id_to_save < 1 ? -1 :
		[tab_controller tab_for_item_id:id_to_save];

	DLOG(@"Ipad saving article %d for tab %d", id_to_save, tab_to_save);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:tab_to_save forKey:LAST_TAB];
	[defaults setInteger:id_to_save forKey:LAST_VIEWED_ID];
}

/** Another hack to prevent rotation bugs. 
 * This hack is for fullscreen video playback. If the user starts
 * a video in portrait and then rotates, the view is rotated but the
 * message willHideViewController is never triggered. This function
 * tries to fix this.
 * This method is intented to be called after another fix for the
 * status bar is performed in the FLMovie_view_controller.
 */
- (void)hide_landscape_button
{
	const UIInterfaceOrientation orientation = [self interfaceOrientation];
	if (UIInterfaceOrientationLandscapeLeft == orientation ||
			UIInterfaceOrientationLandscapeRight == orientation) {
		/* Simulate the message that would happen during rotation. */
		[self splitViewController:self willShowViewController:nil
			invalidatingBarButtonItem:nil];
	}
}

#pragma mark -
#pragma mark Rotating the view, popping buttons

- (void)splitViewController:(UISplitViewController*)split_view
	willHideViewController:(UIViewController *)view_controller
	withBarButtonItem:(UIBarButtonItem*)pop_button
	forPopoverController:(UIPopoverController*)pop_controller
{
	DLOG(@"Will hide splitter master view, going portrait");
	self.pop_controller = pop_controller;
	self.pop_button = pop_button;
	[self set_pop_button_title];

	[self set_first_controller_button:pop_button];
}

- (void)splitViewController:(UISplitViewController*)split_view
	willShowViewController:(UIViewController *)view_controller
	invalidatingBarButtonItem:(UIBarButtonItem *)pop_button
{
	DLOG(@"Will show splitter master view, going landscape");
	[self set_first_controller_button:nil];
	self.pop_controller = nil;
	self.pop_button = nil;
}

/** User touched the sections button.
 * If we are viewing the photo browser, request to not hide the to bar.
 */
- (void)splitViewController:(UISplitViewController*)split_view
	popoverController:(UIPopoverController*)pop_controller
	willPresentViewController:(UIViewController *)view_controller
{
	UIViewController *controller = [self first_controller];
	ASK_GETTER(controller, cancel_hud_hidding, 0);
	ASK_GETTER(controller, cancel_previous_action_sheet, 0);
}


@end
