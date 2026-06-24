# Product

## Register

product

## Users

Grupos de amigos y familia en reuniones presenciales — 4 a 10 personas compartiendo uno o dos dispositivos móviles o tablets en el mismo espacio físico. El contexto es ruidoso, mal iluminado, con mucha actividad social alrededor. Los usuarios no leen instrucciones; esperan que la app sea obvia en 2 segundos. La partida completa no debería llevar más de 5 minutos.

## Product Purpose

El Impostor v2 es la segunda versión del juego de fiesta por turnos donde uno o varios jugadores reciben una palabra/tema diferente al resto del grupo y deben ocultarlo. El producto existe para facilitar ese momento social sin convertirse en el centro de atención: la app es el árbitro, no el entretenimiento. Éxito significa que nadie menciona la app durante la partida — solo el juego.

El v2 es un rediseño visual puro con el mismo stack funcional (React + Vite + Capacitor + Firebase), con foco en: experiencia fluida desde instalación hasta primera partida, y una identidad visual que se sienta premium y diferente al v1.

## Brand Personality

Juguetona · Caótica · Expresiva

Voz de fiesta con carácter propio. Tipografía con personalidad, colores vivos y contrastados, micro-interacciones con energía física. La UI celebra el caos controlado de una reunión social — no intenta suavizarlo ni ordenarlo. Es exuberante donde importa (revelación de rol, transiciones entre estados) y directa donde se necesita (lectura rápida del estado de la partida).

## Anti-references

- Interfaces claras y "seguras" estilo Kahoot o Jackbox — colores primarios saturados sin personalidad, redondeado genérico, branding de quiz corporativo.
- Tarjetas ultra-redondeadas (> 16px en elementos de juego). Los bordes blandos contradicen la tensión del juego.
- Glassmorphism decorativo — blur como relleno visual sin propósito.
- Gradientes tipográficos (`background-clip: text`) — decorativo, nunca significativo.
- Animaciones lentas estilo "spa" (> 400ms en interacciones de juego). La urgencia social no espera.
- El v1 de El Impostor en su paleta AMOLED/industrial fría: en v2 la personalidad es opuesta.

## Design Principles

1. **El juego manda, la UI sirve.** Cada pantalla existe para hacer avanzar la partida, no para lucirse. La UI desaparece cuando el juego está en marcha.
2. **Energía física en cada interacción.** Tap, swipe, reveal — todo tiene feedback inmediato. Ni un toque sin respuesta visual o háptica.
3. **Legible a distancia y en cualquier luz.** Contraste alto siempre. Tipos grandes donde importa. El dispositivo puede estar a 50cm sobre una mesa ruidosa.
4. **Expresivo pero no lento.** Las animaciones son rápidas (150–300ms), elásticas donde corresponde, pero nunca bloquean el progreso del juego.
5. **Una ruta, cero ambigüedad.** En cada pantalla hay exactamente una acción primaria obvia. Sin menús, sin submenús, sin opciones ocultas durante la partida.
