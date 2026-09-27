# ABC Mágico – Aprende jugando

App educativa del abecedario para niños de 3 a 7 años, hecha en **Flutter**.

- Bienvenida con nombre, menú, las 27 letras (con Ñ), 8 juegos, premio, progreso y zona de padres.
- **15 niveles** (A-B-C, D-E-F… X-Y-Z, vocales, 3 repasos, minúsculas y todo el abecedario). Cada juego usa las letras del nivel elegido; el siguiente nivel se abre al completar 3 juegos distintos.
- Las 27 letras tienen palabra, dibujo y audio; el trazado funciona con todas (mayúsculas y minúsculas).
- Voz de Lumi con tus audios grabados (`assets/audio`) y voz del teléfono para el nombre del niño o niña.
- Progreso, estrellas, medallas y ajustes guardados en el teléfono.
- Funciona sin internet (la tipografía se descarga la primera vez; ver abajo).

---

## Opción A — Sacar el APK con GitHub (sin instalar nada)

1. Crea una cuenta gratis en <https://github.com> e inicia sesión.
2. Arriba a la derecha: **+ → New repository**. Ponle de nombre `abc-magico` y pulsa **Create repository**.
3. En la página del repositorio pulsa **uploading an existing file**.
4. Descomprime `abc_magico.zip` en tu PC, entra a la carpeta `abc_magico` y **arrastra todo su contenido**
   (las carpetas `lib`, `assets`, `test`, `tool`, `.github` y los archivos `pubspec.yaml`, `README.md`).
   > La carpeta `.github` está oculta en Windows: activa *Ver → Elementos ocultos* en el Explorador.
5. Pulsa **Commit changes**.
6. Ve a la pestaña **Actions**: verás "Compilar APK" trabajando (5–8 minutos).
7. Cuando salga el visto verde ✅, entra a la ejecución y abajo, en **Artifacts**, descarga **ABC-Magico-APK**.
8. Descomprime el zip descargado: adentro está `app-release.apk`. Pásalo al teléfono y ábrelo
   (acepta *Instalar apps de origen desconocido*).

Cada vez que subas un cambio, GitHub compila un APK nuevo solo.

## Opción B — Compilar en tu PC

1. Instala **Flutter**: <https://docs.flutter.dev/get-started/install/windows/mobile> (incluye Android Studio).
2. En una terminal, dentro de la carpeta `abc_magico`:

   ```bash
   flutter create --platforms=android --org com.abcmagico --project-name abc_magico .
   python tool/patch_android.py
   flutter pub get
   dart run flutter_launcher_icons
   flutter run            # para probar con el teléfono conectado por USB
   flutter build apk --release
   ```

3. El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

---

## Estructura

```
lib/
  main.dart               arranque, reloj de minutos de uso
  core/theme.dart         colores y tipografías
  core/data.dart          27 letras, palabras y dibujos
  core/state.dart         progreso, nombre, medallas, ajustes (se guardan en el teléfono)
  core/voice.dart         voz de Lumi: audios grabados + voz del teléfono + efectos
  widgets/ui.dart         botones brillantes, letrero de madera, Lumi, fondo, etc.
  screens/                una pantalla por archivo
assets/
  audio/                  70 audios grabados (L_A.mp3, W_arbol.mp3, P_genial.mp3…)
  sfx/                    efectos de sonido
  img/                    ilustraciones (SVG)
  icon/                   ícono de la app
```

### Cambiar o agregar audios
Reemplaza el archivo en `assets/audio` con el mismo nombre:
- Letras: `L_A.mp3` … `L_Z.mp3` (la Ñ es `L_NY.mp3`)
- Palabras: `W_arbol.mp3`, `W_casa.mp3`… (sin tildes ni ñ: `W_nandu.mp3`)
- Felicitaciones: `P_muybien`, `P_genial`, `P_excelente`, `P_esoes`, `P_lograste`
- Ánimo: `A_casi`, `A_intenta`, `A_escucha`, `A_tupuedes`
- Instrucciones: `I_escuchaste`, `I_toca`, `I_traza`, `I_falta`, `I_parejas`, `I_orden`, `I_escondidas`

### Tipografía sin internet desde el primer uso (opcional)
La app usa las fuentes **Baloo 2** y **Nunito** (paquete `google_fonts`). Se descargan la primera vez
que el teléfono tiene internet y luego quedan guardadas. Para incluirlas desde el inicio, descarga los
archivos `.ttf` de <https://fonts.google.com>, ponlos en `assets/fonts/` y agrega `- assets/fonts/`
en la sección `assets` de `pubspec.yaml`.

### Publicar en Google Play
Para la tienda hace falta una firma propia y un `.aab` (`flutter build appbundle`).
Guía oficial: <https://docs.flutter.dev/deployment/android>
