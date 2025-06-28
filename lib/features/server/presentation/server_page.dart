                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Image.asset(
                      isDark ? 'assets/images/logo_light.png' : 'assets/images/logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                ), 