import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conditional_rendering/conditional.dart';
import 'package:take_away/layout/admin_cubit/cubit.dart';
import 'package:take_away/layout/admin_cubit/states.dart';
import 'package:take_away/model/drinks_model.dart';
import 'package:take_away/shared/components/components.dart';

import 'add_new_drink.dart';
import 'edit_drink_data.dart';

class ColdDrinksAdminScreen extends StatelessWidget {
  const ColdDrinksAdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var cubit = AdminCubit.get(context);
    return Builder(builder: (context) {
      cubit.getColdDrinksData();
      return BlocConsumer<AdminCubit, AdminStates>(
        listener: (context, state) {},
        builder: (context, state) => SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state is LoadingGetDrinksDataState)
                  const LinearProgressIndicator(),
                if (state is LoadingGetDrinksDataState)
                  const SizedBox(
                    height: 10,
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      navigateAndFinishTo(context, AddNewDrink(isCold: true,));
                    },
                    child: Center(
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color:
                            Theme.of(context).primaryColor.withOpacity(0.4),
                            borderRadius: BorderRadiusDirectional.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Expanded(
                              child: Text(
                                'مشروب جديد',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 60,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Conditional.single(
                  conditionBuilder: (context) => cubit.coldDrinksMenu.isNotEmpty,
                  widgetBuilder: (context) => GridView.count(
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                    childAspectRatio: 1 / .8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    children: List.generate(
                        cubit.coldDrinksMenu.length,
                            (index) => coldMenuItemBuilder(
                            model: cubit.coldDrinksMenu[index],
                            context: context)),
                  ),
                  fallbackBuilder: (context) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 150,
                        ),
                        Text(
                          'القائمة فاضية',
                          style: TextStyle(
                            fontSize: 40,
                            color:
                            Theme.of(context).primaryColor.withOpacity(.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  context: context,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

Widget coldMenuItemBuilder(
    {required BuildContext context, required DrinksModel model}) =>
    InkWell(
      onTap: (){
        navigateAndFinishTo(context,  EditDrinkData(model: model,isCold: true,));
      },
      child: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          Image(
            image: NetworkImage(model.drinkImage),
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          ),
          Container(
            width: 100,
            color: Colors.black.withOpacity(0.7),
            child: Text(
              model.drinkName,
              style: const TextStyle(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
